import CoreLocation
import Foundation

final class TripPlanningService {
    func makePlan(
        from places: [Place],
        query: ParsedTravelQuery,
        start: CLLocationCoordinate2D
    ) -> TripPlan {
        let targetDuration = query.durationMinutes ?? 240
        let targetStopCount = min(max(targetDuration / 70, 3), 6)
        let candidates = candidatesForPlan(from: places, query: query, targetStopCount: targetStopCount)
        let ordered = GeoMath.nearestNeighborOrder(places: candidates, start: start)

        var current = start
        var elapsedMinutes = 0
        var stops: [TripStop] = []

        for (index, place) in ordered.enumerated() {
            let travelMinutes = travelMinutesBetween(current, place.coordinate, mode: query.travelMode)
            elapsedMinutes += travelMinutes

            let stayMinutes = min(place.category.defaultStayMinutes, max(20, targetDuration / 3))
            let stop = TripStop(
                id: "\(place.id)_stop_\(index + 1)",
                place: place,
                order: index + 1,
                arrivalOffsetMinutes: elapsedMinutes,
                stayMinutes: stayMinutes,
                reason: reason(for: place, query: query)
            )
            stops.append(stop)

            elapsedMinutes += stayMinutes
            current = place.coordinate

            if elapsedMinutes >= targetDuration { break }
        }

        let coordinates = [start] + stops.map { $0.place.coordinate }
        let distance = GeoMath.routeDistanceMeters(coordinates)

        return TripPlan(
            id: UUID().uuidString,
            title: title(for: query, stops: stops),
            summary: summary(for: query, stops: stops, distance: distance),
            travelMode: query.travelMode,
            startLatitude: start.latitude,
            startLongitude: start.longitude,
            stops: stops,
            totalDistanceMeters: distance,
            totalDurationMinutes: elapsedMinutes,
            createdAt: Date()
        )
    }

    private func candidatesForPlan(
        from places: [Place],
        query: ParsedTravelQuery,
        targetStopCount: Int
    ) -> [Place] {
        var selected: [Place] = []
        let preferredCategories = Set(query.categories)

        selected.append(contentsOf: places.filter { preferredCategories.contains($0.category) })

        if query.needsMeal, !selected.contains(where: { $0.category == .restaurant || $0.category == .cafe }) {
            selected.append(contentsOf: places.filter { $0.category == .restaurant || $0.category == .cafe })
        }

        if selected.isEmpty {
            selected = places
        }

        return Array(selected.prefix(max(targetStopCount, 3)))
    }

    private func travelMinutesBetween(
        _ start: CLLocationCoordinate2D,
        _ end: CLLocationCoordinate2D,
        mode: TravelMode
    ) -> Int {
        let distance = GeoMath.distanceMeters(from: start, to: end)

        let metersPerMinute: Double
        switch mode {
        case .walking:
            metersPerMinute = 75
        case .transit:
            metersPerMinute = 280
        case .driving:
            metersPerMinute = 450
        }

        return max(3, Int(ceil(distance / metersPerMinute)))
    }

    private func reason(for place: Place, query: ParsedTravelQuery) -> String {
        let matchingTags = place.tags.filter { tag in
            query.constraints.contains { constraint in
                tag.localizedCaseInsensitiveContains(constraint)
                    || constraint.localizedCaseInsensitiveContains(tag)
            }
        }

        if let first = matchingTags.first {
            return "Matches your preference for \(first) places and keeps the route compact."
        }

        return "Fits the requested \(place.category.title.lowercased()) category and works well in the route order."
    }

    private func title(for query: ParsedTravelQuery, stops: [TripStop]) -> String {
        let pace = query.constraints.contains("relaxed") ? "Relaxed" : "Smart"
        let duration = query.durationMinutes.map { "\($0 / 60)h" } ?? "Half-day"
        return "\(pace) \(duration) Route"
    }

    private func summary(for query: ParsedTravelQuery, stops: [TripStop], distance: Double) -> String {
        let stopNames = stops.map { $0.place.name }.joined(separator: ", ")
        let kilometers = distance / 1_000
        return "A \(query.travelMode.title.lowercased()) plan with \(stops.count) stops over \(String(format: "%.1f", kilometers)) km: \(stopNames)."
    }
}
