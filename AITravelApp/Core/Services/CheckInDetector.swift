import CoreLocation
import Foundation

final class CheckInDetector {
    private var arrivalStartByStopID: [String: Date] = [:]
    private let dwellTimeSeconds: TimeInterval

    init(dwellTimeSeconds: TimeInterval = 30) {
        self.dwellTimeSeconds = dwellTimeSeconds
    }

    func promptIfNeeded(
        location: CLLocationCoordinate2D,
        plan: TripPlan?,
        existingCheckIns: [CheckIn],
        now: Date = Date()
    ) -> CheckInPrompt? {
        guard let plan else { return nil }
        let checkedPlaceIDs = Set(existingCheckIns.map { $0.place.id })

        for stop in plan.stops where !checkedPlaceIDs.contains(stop.place.id) {
            let distance = GeoMath.distanceMeters(from: location, to: stop.place.coordinate)
            let radius = stop.place.category.checkInRadiusMeters

            guard distance <= radius else {
                arrivalStartByStopID[stop.id] = nil
                continue
            }

            let arrivedAt = arrivalStartByStopID[stop.id] ?? now
            arrivalStartByStopID[stop.id] = arrivedAt

            if now.timeIntervalSince(arrivedAt) >= dwellTimeSeconds {
                return CheckInPrompt(
                    stop: stop,
                    distanceMeters: distance,
                    arrivedAt: arrivedAt
                )
            }
        }

        return nil
    }
}
