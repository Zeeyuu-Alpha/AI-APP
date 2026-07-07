import CoreLocation
import XCTest
@testable import AITravelApp

final class TripPlanningServiceTests: XCTestCase {
    func testPlanCreatesOrderedStops() {
        let planner = TripPlanningService()
        let query = ParsedTravelQuery.defaultTripPlan()
        let start = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)

        let plan = planner.makePlan(
            from: SeedPlaces.all,
            query: query,
            start: start
        )

        XCTAssertGreaterThanOrEqual(plan.stops.count, 3)
        XCTAssertEqual(plan.stops.map(\.order), Array(1...plan.stops.count))
        XCTAssertGreaterThan(plan.totalDurationMinutes, 0)
        XCTAssertGreaterThan(plan.totalDistanceMeters, 0)
    }
}
