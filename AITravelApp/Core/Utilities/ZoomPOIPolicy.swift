import Foundation

enum ZoomPOIPolicy {
    static func categories(for zoomLevel: Double) -> [PlaceCategory] {
        switch zoomLevel {
        case ..<8:
            return [.attraction, .viewpoint]
        case 8..<12:
            return [.attraction, .viewpoint, .museum, .park]
        case 12..<15:
            return [.attraction, .museum, .park, .shopping, .restaurant]
        case 15..<17:
            return [.restaurant, .cafe, .shopping, .bar, .attraction, .museum]
        default:
            return PlaceCategory.allCases
        }
    }

    static func radiusMeters(for zoomLevel: Double) -> Double {
        switch zoomLevel {
        case ..<8: return 3_000_000
        case 8..<12: return 300_000
        case 12..<15: return 40_000
        case 15..<17: return 10_000
        default: return 3_500
        }
    }

    static func message(for zoomLevel: Double) -> String {
        switch zoomLevel {
        case ..<8:
            return "Showing major city-level landmarks."
        case 8..<12:
            return "Showing major attractions and parks."
        case 12..<15:
            return "Showing attractions, museums, parks, shopping and restaurants."
        case 15..<17:
            return "Showing restaurants, cafes, bars and nearby highlights."
        default:
            return "Showing fine-grained nearby places."
        }
    }
}
