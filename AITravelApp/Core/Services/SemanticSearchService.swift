import CoreLocation
import Foundation

final class SemanticSearchService {
    private let apiClient: TravelAPIClient

    init(apiClient: TravelAPIClient) {
        self.apiClient = apiClient
    }

    func loadPOIs(
        center: CLLocationCoordinate2D,
        zoomLevel: Double,
        categories: [PlaceCategory]
    ) async throws -> [Place] {
        try await apiClient.loadPOIs(
            center: center,
            zoomLevel: zoomLevel,
            categories: categories
        )
    }

    func search(
        text: String,
        center: CLLocationCoordinate2D
    ) async throws -> SemanticSearchResult {
        let parsedQuery = parse(text: text)
        let places = try await apiClient.searchPlaces(
            parsedQuery: parsedQuery,
            center: center
        )

        return SemanticSearchResult(
            parsedQuery: parsedQuery,
            places: places,
            explanation: explanation(for: parsedQuery, resultCount: places.count)
        )
    }

    func parse(text: String) -> ParsedTravelQuery {
        let lowered = text.lowercased()
        let intent: TravelIntent = containsAny(
            lowered,
            tokens: ["plan", "route", "itinerary", "trip", "安排", "路线", "行程", "规划"]
        ) ? .tripPlan : .placeSearch

        var categories: [PlaceCategory] = []
        appendCategory(.restaurant, to: &categories, when: containsAny(lowered, tokens: ["restaurant", "food", "meal", "dinner", "lunch", "餐厅", "吃饭", "晚餐", "午餐"]))
        appendCategory(.cafe, to: &categories, when: containsAny(lowered, tokens: ["coffee", "cafe", "咖啡"]))
        appendCategory(.museum, to: &categories, when: containsAny(lowered, tokens: ["museum", "art", "gallery", "博物馆", "美术馆", "艺术"]))
        appendCategory(.park, to: &categories, when: containsAny(lowered, tokens: ["park", "garden", "公园", "花园"]))
        appendCategory(.viewpoint, to: &categories, when: containsAny(lowered, tokens: ["photo", "view", "skyline", "拍照", "出片", "风景", "景观"]))
        appendCategory(.shopping, to: &categories, when: containsAny(lowered, tokens: ["shop", "shopping", "market", "购物", "商场", "市集"]))
        appendCategory(.bar, to: &categories, when: containsAny(lowered, tokens: ["bar", "wine", "cocktail", "酒吧", "小酒馆"]))
        appendCategory(.attraction, to: &categories, when: containsAny(lowered, tokens: ["classic", "landmark", "sight", "景点", "经典", "地标"]))

        if categories.isEmpty {
            categories = intent == .tripPlan
                ? [.attraction, .museum, .park, .restaurant]
                : [.attraction, .restaurant, .cafe, .museum, .park]
        }

        let needsMeal = containsAny(lowered, tokens: ["meal", "food", "lunch", "dinner", "吃饭", "午餐", "晚餐", "中间吃"])
        if needsMeal, !categories.contains(.restaurant) {
            categories.append(.restaurant)
        }

        return ParsedTravelQuery(
            intent: intent,
            rawText: text,
            categories: Array(Set(categories)).sorted { $0.rawValue < $1.rawValue },
            constraints: constraints(from: lowered),
            maxDistanceMeters: maxDistance(from: lowered),
            durationMinutes: duration(from: lowered),
            needsMeal: needsMeal,
            budget: budget(from: lowered),
            travelMode: travelMode(from: lowered),
            rankingPreference: .balanced
        )
    }

    private func explanation(for query: ParsedTravelQuery, resultCount: Int) -> String {
        let categoryText = query.categories.map(\.title).joined(separator: ", ")
        let intentText = query.intent == .tripPlan ? "trip planning" : "place search"

        if query.constraints.isEmpty {
            return "Parsed \(intentText) and found \(resultCount) results across \(categoryText)."
        }

        return "Parsed \(intentText), prioritized \(query.constraints.joined(separator: ", ")), and found \(resultCount) results across \(categoryText)."
    }

    private func constraints(from text: String) -> [String] {
        var constraints: [String] = []
        append("photo", to: &constraints, when: containsAny(text, tokens: ["photo", "photogenic", "拍照", "出片"]))
        append("romantic", to: &constraints, when: containsAny(text, tokens: ["romantic", "date", "couple", "情侣", "约会"]))
        append("relaxed", to: &constraints, when: containsAny(text, tokens: ["relaxed", "easy", "not tiring", "轻松", "不要太累", "不累"]))
        append("classic", to: &constraints, when: containsAny(text, tokens: ["classic", "must-see", "经典", "必去"]))
        append("local", to: &constraints, when: containsAny(text, tokens: ["local", "hidden", "less crowded", "本地", "小众", "人少"]))
        append("open", to: &constraints, when: containsAny(text, tokens: ["open", "tonight", "now", "营业", "今晚", "现在开"]))
        return constraints
    }

    private func maxDistance(from text: String) -> CLLocationDistance? {
        if containsAny(text, tokens: ["walking", "walk", "步行", "走路"]) {
            if containsAny(text, tokens: ["20 min", "20分钟", "20 分钟"]) {
                return 1_600
            }
            return 3_000
        }

        if containsAny(text, tokens: ["nearby", "附近", "周边"]) {
            return 5_000
        }

        return nil
    }

    private func duration(from text: String) -> Int? {
        if containsAny(text, tokens: ["half day", "half-day", "半天"]) {
            return 240
        }
        if containsAny(text, tokens: ["full day", "full-day", "one day", "一天"]) {
            return 480
        }
        if containsAny(text, tokens: ["4 hours", "4小时", "4 小时"]) {
            return 240
        }
        if containsAny(text, tokens: ["3 hours", "3小时", "3 小时"]) {
            return 180
        }
        return nil
    }

    private func budget(from text: String) -> BudgetLevel? {
        if containsAny(text, tokens: ["cheap", "budget", "affordable", "便宜", "不要太贵", "不贵"]) {
            return .low
        }
        if containsAny(text, tokens: ["medium", "mid", "中等", "适中"]) {
            return .medium
        }
        if containsAny(text, tokens: ["high-end", "luxury", "fancy", "高级", "贵一点"]) {
            return .high
        }
        return nil
    }

    private func travelMode(from text: String) -> TravelMode {
        if containsAny(text, tokens: ["drive", "car", "开车", "打车"]) {
            return .driving
        }
        if containsAny(text, tokens: ["metro", "subway", "transit", "地铁", "公交"]) {
            return .transit
        }
        return .walking
    }

    private func appendCategory(_ category: PlaceCategory, to categories: inout [PlaceCategory], when condition: Bool) {
        guard condition, !categories.contains(category) else { return }
        categories.append(category)
    }

    private func append(_ value: String, to values: inout [String], when condition: Bool) {
        guard condition, !values.contains(value) else { return }
        values.append(value)
    }

    private func containsAny(_ text: String, tokens: [String]) -> Bool {
        tokens.contains { text.localizedCaseInsensitiveContains($0) }
    }
}
