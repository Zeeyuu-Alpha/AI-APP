import CoreLocation
import XCTest
@testable import AITravelApp

final class SemanticSearchServiceTests: XCTestCase {
    func testChineseRestaurantSearchParsing() {
        let service = SemanticSearchService(
            apiClient: MockTravelAPIClient(seedPlaces: SeedPlaces.all)
        )

        let query = service.parse(text: "找附近适合拍照、不要太贵、今晚还营业的餐厅")

        XCTAssertEqual(query.intent, .placeSearch)
        XCTAssertTrue(query.categories.contains(.restaurant))
        XCTAssertTrue(query.constraints.contains("photo"))
        XCTAssertTrue(query.constraints.contains("open"))
        XCTAssertEqual(query.budget, .low)
        XCTAssertEqual(query.maxDistanceMeters, 5_000)
    }

    func testTripPlanParsing() {
        let service = SemanticSearchService(
            apiClient: MockTravelAPIClient(seedPlaces: SeedPlaces.all)
        )

        let query = service.parse(text: "Plan a relaxed half-day classic route with lunch")

        XCTAssertEqual(query.intent, .tripPlan)
        XCTAssertTrue(query.constraints.contains("relaxed"))
        XCTAssertTrue(query.constraints.contains("classic"))
        XCTAssertTrue(query.needsMeal)
        XCTAssertEqual(query.durationMinutes, 240)
    }
}
