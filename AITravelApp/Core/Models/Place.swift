import CoreLocation
import Foundation

enum PlaceSource: String, Codable {
    case localSeed
    case mapKit
    case backend
    case mapbox
    case foursquare
    case openTripMap
    case yelp
}

struct Place: Identifiable, Codable, Hashable {
    let id: String
    let source: PlaceSource
    let sourcePlaceID: String
    let name: String
    let category: PlaceCategory
    let latitude: Double
    let longitude: Double
    let address: String
    let rating: Double?
    let priceLevel: Int?
    let isOpenNow: Bool?
    let tags: [String]
    let summary: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distanceMeters(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        GeoMath.distanceMeters(from: self.coordinate, to: coordinate)
    }
}
