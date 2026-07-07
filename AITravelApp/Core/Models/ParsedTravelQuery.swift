import CoreLocation
import Foundation

enum TravelIntent: String, Codable {
    case placeSearch
    case tripPlan
}

enum TravelMode: String, CaseIterable, Codable, Identifiable {
    case walking
    case transit
    case driving

    var id: String { rawValue }

    var title: String {
        switch self {
        case .walking: return "Walking"
        case .transit: return "Transit"
        case .driving: return "Driving"
        }
    }
}

enum BudgetLevel: String, Codable {
    case low
    case medium
    case high
}

struct RankingPreference: Codable, Hashable {
    var semanticMatch: Double
    var distance: Double
    var rating: Double
    var popularity: Double
    var openNow: Double

    static let balanced = RankingPreference(
        semanticMatch: 0.35,
        distance: 0.20,
        rating: 0.15,
        popularity: 0.10,
        openNow: 0.10
    )
}

struct ParsedTravelQuery: Codable, Hashable {
    var intent: TravelIntent
    var rawText: String
    var categories: [PlaceCategory]
    var constraints: [String]
    var maxDistanceMeters: CLLocationDistance?
    var durationMinutes: Int?
    var needsMeal: Bool
    var budget: BudgetLevel?
    var travelMode: TravelMode
    var rankingPreference: RankingPreference

    static func defaultSearch() -> ParsedTravelQuery {
        ParsedTravelQuery(
            intent: .placeSearch,
            rawText: "",
            categories: [.attraction, .restaurant, .cafe],
            constraints: [],
            maxDistanceMeters: 3_000,
            durationMinutes: nil,
            needsMeal: false,
            budget: nil,
            travelMode: .walking,
            rankingPreference: .balanced
        )
    }

    static func defaultTripPlan() -> ParsedTravelQuery {
        ParsedTravelQuery(
            intent: .tripPlan,
            rawText: "",
            categories: [.attraction, .museum, .park, .restaurant],
            constraints: ["relaxed", "classic"],
            maxDistanceMeters: 6_000,
            durationMinutes: 240,
            needsMeal: true,
            budget: .medium,
            travelMode: .walking,
            rankingPreference: .balanced
        )
    }
}

struct SemanticSearchResult {
    let parsedQuery: ParsedTravelQuery
    let places: [Place]
    let explanation: String
}
