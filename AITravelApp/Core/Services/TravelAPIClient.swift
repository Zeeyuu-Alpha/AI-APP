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

        var categoryMatches: [Place] = []
        for place in seedPlaces where categories.contains(place.category) {
            categoryMatches.append(place)
        }

        var nearby: [Place] = []
        for place in categoryMatches where place.distanceMeters(to: center) <= radius {
            nearby.append(place)
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
        let selectedCategories: [PlaceCategory]
        if parsedQuery.categories.isEmpty {
            selectedCategories = PlaceCategory.allCases
        } else {
            selectedCategories = parsedQuery.categories
        }
        let maxDistance = parsedQuery.maxDistanceMeters ?? 25_000

        var categoryMatches: [Place] = []
        for place in seedPlaces where selectedCategories.contains(place.category) {
            categoryMatches.append(place)
        }

        var distanceMatches: [Place] = []
        for place in categoryMatches {
            let distance = place.distanceMeters(to: center)
            if distance <= maxDistance || maxDistance >= 500_000 {
                distanceMatches.append(place)
            }
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
        return places.sorted { lhs, rhs in
            lhs.distanceMeters(to: center) < rhs.distanceMeters(to: center)
        }
    }

    private func rankPlaces(
        _ places: [Place],
        query: ParsedTravelQuery,
        center: CLLocationCoordinate2D
    ) -> [Place] {
        var rankedPlaces: [RankedPlace] = []
        for place in places {
            let rankedPlace = RankedPlace(
                place: place,
                score: score(place, query: query, center: center)
            )
            rankedPlaces.append(rankedPlace)
        }

        let sortedPlaces = rankedPlaces.sorted { lhs, rhs in
            lhs.score > rhs.score
        }

        var resultPlaces: [Place] = []
        for rankedPlace in sortedPlaces {
            resultPlaces.append(rankedPlace.place)
        }
        return resultPlaces
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

        let weightedSemanticScore = semanticScore * weights.semanticMatch
        let weightedDistanceScore = distanceScore * weights.distance
        let weightedRatingScore = ratingScore * weights.rating
        let weightedPriceScore = priceScore * weights.popularity
        let weightedOpenNowScore = openNowScore * weights.openNow

        return weightedSemanticScore
            + weightedDistanceScore
            + weightedRatingScore
            + weightedPriceScore
            + weightedOpenNowScore
    }

    private func semanticMatchScore(place: Place, constraints: [String]) -> Double {
        guard !constraints.isEmpty else { return 0.7 }

        var placeTokens = place.tags
        placeTokens.append(place.category.rawValue)
        placeTokens.append(place.name.lowercased())

        var matchCount = 0
        for constraint in constraints where containsSemanticMatch(tokens: placeTokens, constraint: constraint) {
            matchCount += 1
        }

        return min(1, 0.45 + Double(matchCount) / Double(max(constraints.count, 1)))
    }

    private func containsSemanticMatch(tokens: [String], constraint: String) -> Bool {
        for token in tokens {
            if token.localizedCaseInsensitiveContains(constraint) {
                return true
            }
            if constraint.localizedCaseInsensitiveContains(token) {
                return true
            }
        }
        return false
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
