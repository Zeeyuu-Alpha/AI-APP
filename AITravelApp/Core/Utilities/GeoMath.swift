import CoreLocation
import Foundation

enum GeoMath {
    static func distanceMeters(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }

    static func routeDistanceMeters(_ coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0 }

        return zip(coordinates, coordinates.dropFirst()).reduce(0) { partial, pair in
            partial + distanceMeters(from: pair.0, to: pair.1)
        }
    }

    static func nearestNeighborOrder(
        places: [Place],
        start: CLLocationCoordinate2D
    ) -> [Place] {
        var remaining = places
        var ordered: [Place] = []
        var current = start

        while !remaining.isEmpty {
            let nearestIndex = remaining.indices.min { left, right in
                remaining[left].distanceMeters(to: current) < remaining[right].distanceMeters(to: current)
            }

            guard let index = nearestIndex else { break }
            let next = remaining.remove(at: index)
            ordered.append(next)
            current = next.coordinate
        }

        return ordered
    }
}
