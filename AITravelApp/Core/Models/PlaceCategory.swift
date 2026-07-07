import CoreLocation
import Foundation

enum PlaceCategory: String, CaseIterable, Codable, Identifiable {
    case attraction
    case restaurant
    case cafe
    case hotel
    case shopping
    case viewpoint
    case museum
    case park
    case bar
    case transport

    var id: String { rawValue }

    var title: String {
        switch self {
        case .attraction: return "Attraction"
        case .restaurant: return "Restaurant"
        case .cafe: return "Cafe"
        case .hotel: return "Hotel"
        case .shopping: return "Shopping"
        case .viewpoint: return "Viewpoint"
        case .museum: return "Museum"
        case .park: return "Park"
        case .bar: return "Bar"
        case .transport: return "Transit"
        }
    }

    var symbolName: String {
        switch self {
        case .attraction: return "star.fill"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .hotel: return "bed.double.fill"
        case .shopping: return "bag.fill"
        case .viewpoint: return "camera.fill"
        case .museum: return "building.columns.fill"
        case .park: return "leaf.fill"
        case .bar: return "wineglass.fill"
        case .transport: return "tram.fill"
        }
    }

    var defaultStayMinutes: Int {
        switch self {
        case .restaurant: return 60
        case .cafe: return 35
        case .hotel: return 0
        case .shopping: return 50
        case .bar: return 45
        case .transport: return 10
        case .park: return 40
        case .viewpoint: return 25
        case .museum: return 90
        case .attraction: return 60
        }
    }

    var checkInRadiusMeters: CLLocationDistance {
        switch self {
        case .restaurant, .cafe, .bar: return 50
        case .museum, .attraction, .viewpoint: return 100
        case .park: return 200
        case .hotel, .shopping, .transport: return 80
        }
    }
}
