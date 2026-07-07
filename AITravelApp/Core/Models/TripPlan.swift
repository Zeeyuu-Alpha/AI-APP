import CoreLocation
import Foundation

struct TripPlan: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let summary: String
    let travelMode: TravelMode
    let startLatitude: Double
    let startLongitude: Double
    let stops: [TripStop]
    let totalDistanceMeters: Double
    let totalDurationMinutes: Int
    let createdAt: Date

    var routeCoordinates: [CLLocationCoordinate2D] {
        let start = CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
        return [start] + stops.map { $0.place.coordinate }
    }
}

struct TripStop: Identifiable, Codable, Hashable {
    let id: String
    let place: Place
    let order: Int
    let arrivalOffsetMinutes: Int
    let stayMinutes: Int
    let reason: String
}
