import CoreLocation
import Foundation

enum CheckInSource: String, Codable {
    case autoGeofence
    case manual
}

struct CheckIn: Identifiable, Codable, Hashable {
    let id: String
    let tripID: String?
    let place: Place
    let latitude: Double
    let longitude: Double
    let checkedInAt: Date
    let source: CheckInSource

    init(
        id: String,
        tripID: String?,
        place: Place,
        coordinate: CLLocationCoordinate2D,
        checkedInAt: Date,
        source: CheckInSource
    ) {
        self.id = id
        self.tripID = tripID
        self.place = place
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.checkedInAt = checkedInAt
        self.source = source
    }
}

struct CheckInPrompt: Identifiable, Equatable {
    let id = UUID()
    let stop: TripStop
    let distanceMeters: Double
    let arrivedAt: Date
}
