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

        let categoryMatches = seedPlaces.filter { place in
            selectedCategories.contains(place.category)
        }
        let nearby = categoryMatches.filter { place in
            place.distanceMeters(to: center) <= radius
        }
        let sortedNearby = sortByDistance(nearby, from: center)

        if !sortedNearby.isEmpty {
            return Array(sortedNearby.prefix(24))
        }

        let fallback = sortByDistance(categoryMatches, from: center)
        return Array(fallback.prefix(8))
    }

    func searchPlaces(
        parsedQuery: ParsedTravelQuery,
        center: CLLocationCoordinate2D
    ) async throws -> [Place] {
        let categories = parsedQuery.categories.isEmpty
            ? Set(PlaceCategory.allCases)
            : Set(parsedQuery.categories)
        let maxDistance = parsedQuery.maxDistanceMeters ?? 25_000

        let categoryMatches = seedPlaces.filter { place in
            categories.contains(place.category)
        }
        let distanceMatches = categoryMatches.filter { place in
            let distance = place.distanceMeters(to: center)
            return distance <= maxDistance || maxDistance >= 500_000
        }
        let matching = rankPlaces(distanceMatches, query: parsedQuery, center: center)

        if !matching.isEmpty {
            return Array(matching.prefix(12))
        }

        let fallback = rankPlaces(categoryMatches, query: parsedQuery, center: center)
        return Array(fallback.prefix(12))
    }

    private func sortByDistance(
        _ places: [Place],
        from center: CLLocationCoordinate2D
    ) -> [Place] {
        places.sorted { lhs, rhs in
            lhs.distanceMeters(to: center) < rhs.distanceMeters(to: center)
        }
    }

    private func rankPlaces(
        _ places: [Place],
        query: ParsedTravelQuery,
        center: CLLocationCoordinate2D
    ) -> [Place] {
        let rankedPlaces = places.map { place in
            RankedPlace(
                place: place,
                score: score(place, query: query, center: center)
            )
        }
        let sortedPlaces = rankedPlaces.sorted { lhs, rhs in
            lhs.score > rhs.score
        }
        return sortedPlaces.map { rankedPlace in
            rankedPlace.place
        }
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
            containsSemanticMatch(tokens: placeTokens, constraint: constraint)
        }

        return min(1, 0.45 + Double(matched.count) / Double(max(constraints.count, 1)))
    }

    private func containsSemanticMatch(tokens: Set<String>, constraint: String) -> Bool {
        tokens.contains { token in
            token.localizedCaseInsensitiveContains(constraint)
                || constraint.localizedCaseInsensitiveContains(token)
        }
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
