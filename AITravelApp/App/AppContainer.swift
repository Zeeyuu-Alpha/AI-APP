import Foundation

enum AppContainer {
    @MainActor
    static func makeHomeViewModel() -> TravelHomeViewModel {
        let locationManager = LocationManager()
        let speechInputManager = SpeechInputManager()
        let apiClient = MockTravelAPIClient(seedPlaces: SeedPlaces.all)
        let semanticSearchService = SemanticSearchService(apiClient: apiClient)
        let tripPlanningService = TripPlanningService()
        let checkInDetector = CheckInDetector()

        return TravelHomeViewModel(
            locationManager: locationManager,
            speechInputManager: speechInputManager,
            semanticSearchService: semanticSearchService,
            tripPlanningService: tripPlanningService,
            checkInDetector: checkInDetector
        )
    }
}
