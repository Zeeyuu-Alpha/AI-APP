import CoreLocation
import Foundation

protocol TravelAPIClient {
    func loadPOIs(
        center: CLLocationCoordinate2D,
        zoomLevel: Double,
        categories: [PlaceCategory]
    ) async throws -> [Place]

    func searchPlaces(
        parsedQuery: ParsedTravelQuery,
        center: CLLocationCoordinate2D
    ) async throws -> [Place]
}

final class MockTravelAPIClient: TravelAPIClient {
    private let seedPlaces: [Place]

    init(seedPlaces: [Place]) {
        self.seedPlaces = seedPlaces
    }

    func loadPOIs(
        center: CLLocationCoordinate2D,
        zoomLevel: Double,
        categories: [PlaceCategory]
    ) async throws -> [Place] {
        let radius = ZoomPOIPolicy.radiusMeters(for: zoomLevel)
        let selectedCategories = Set(categories)

        let nearby = seedPlaces
            .filter { selectedCategories.contains($0.category) }
            .filter { $0.distanceMeters(to: center) <= radius }
            .sorted { lhs, rhs in
                lhs.distanceMeters(to: center) < rhs.distanceMeters(to: center)
            }

        if !nearby.isEmpty {
            return Array(nearby.prefix(24))
        }

        return seedPlaces
            .filter { selectedCategories.contains($0.category) }
            .sorted { lhs, rhs in
                lhs.distanceMeters(to: center) < rhs.distanceMeters(to: center)
            }
            .prefix(8)
            .map { $0 }
    }

    func searchPlaces(
        parsedQuery: ParsedTravelQuery,
        center: CLLocationCoordinate2D
    ) async throws -> [Place] {
        let categories = parsedQuery.categories.isEmpty
            ? Set(PlaceCategory.allCases)
            : Set(parsedQuery.categories)
        let maxDistance = parsedQuery.maxDistanceMeters ?? 25_000

        let matching = seedPlaces
            .filter { categories.contains($0.category) }
            .filter { place in
                place.distanceMeters(to: center) <= maxDistance || maxDistance >= 500_000
            }
            .map { place in
                RankedPlace(
                    place: place,
                    score: score(place, query: parsedQuery, center: center)
                )
            }
            .sorted { $0.score > $1.score }
            .map(\.place)

        if !matching.isEmpty {
            return Array(matching.prefix(12))
        }

        return seedPlaces
            .filter { categories.contains($0.category) }
            .map { place in
                RankedPlace(place: place, score: score(place, query: parsedQuery, center: center))
            }
            .sorted { $0.score > $1.score }
            .prefix(12)
            .map(\.place)
    }

    private func score(
        _ place: Place,
        query: ParsedTravelQuery,
        center: CLLocationCoordinate2D
    ) -> Double {
        let semanticScore = semanticMatchScore(place: place, constraints: query.constraints)
        let distanceScore = max(0, 1 - place.distanceMeters(to: center) / 20_000)
        let ratingScore = (place.rating ?? 4.0) / 5.0
        let openNowScore = place.isOpenNow == false ? 0 : 1
        let priceScore = priceMatchScore(place: place, budget: query.budget)
        let weights = query.rankingPreference

        return semanticScore * weights.semanticMatch
            + distanceScore * weights.distance
            + ratingScore * weights.rating
            + priceScore * weights.popularity
            + openNowScore * weights.openNow
    }

    private func semanticMatchScore(place: Place, constraints: [String]) -> Double {
        guard !constraints.isEmpty else { return 0.7 }

        let placeTokens = Set(place.tags + [place.category.rawValue, place.name.lowercased()])
        let matched = constraints.filter { constraint in
            placeTokens.contains { token in
                token.localizedCaseInsensitiveContains(constraint)
                    || constraint.localizedCaseInsensitiveContains(token)
            }
        }

        return min(1, 0.45 + Double(matched.count) / Double(max(constraints.count, 1)))
    }

    private func priceMatchScore(place: Place, budget: BudgetLevel?) -> Double {
        guard let budget, let price = place.priceLevel else { return 0.75 }

        switch budget {
        case .low:
            return price <= 1 ? 1 : 0.25
        case .medium:
            return price <= 3 ? 1 : 0.45
        case .high:
            return 1
        }
    }
}

private struct RankedPlace {
    let place: Place
    let score: Double
}
