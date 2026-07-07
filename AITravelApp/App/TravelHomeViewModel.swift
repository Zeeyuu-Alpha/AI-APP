import Combine
import CoreLocation
import Foundation

@MainActor
final class TravelHomeViewModel: ObservableObject {
    enum ActivePanel: String, CaseIterable, Identifiable {
        case places = "Places"
        case trip = "Trip"
        case checkIns = "Check-ins"

        var id: String { rawValue }
    }

    enum SearchState: Equatable {
        case idle
        case loading
        case loaded(String)
        case failed(String)
    }

    @Published var queryText = ""
    @Published var activePanel: ActivePanel = .places
    @Published var selectedPlace: Place?
    @Published var pendingCheckIn: CheckInPrompt?

    @Published private(set) var places: [Place] = []
    @Published private(set) var tripPlan: TripPlan?
    @Published private(set) var checkIns: [CheckIn] = []
    @Published private(set) var lastParsedQuery: ParsedTravelQuery?
    @Published private(set) var searchState: SearchState = .idle
    @Published private(set) var isVoiceRecording = false
    @Published private(set) var userCoordinate: CLLocationCoordinate2D?

    private let locationManager: LocationManager
    private let speechInputManager: SpeechInputManager
    private let semanticSearchService: SemanticSearchService
    private let tripPlanningService: TripPlanningService
    private let checkInDetector: CheckInDetector

    private var visibleCenter = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
    private var visibleZoomLevel: Double = 13
    private var mapLoadTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(
        locationManager: LocationManager,
        speechInputManager: SpeechInputManager,
        semanticSearchService: SemanticSearchService,
        tripPlanningService: TripPlanningService,
        checkInDetector: CheckInDetector
    ) {
        self.locationManager = locationManager
        self.speechInputManager = speechInputManager
        self.semanticSearchService = semanticSearchService
        self.tripPlanningService = tripPlanningService
        self.checkInDetector = checkInDetector

        bindManagers()
    }

    func bootstrap() async {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        await reloadPOIs(center: visibleCenter, zoomLevel: visibleZoomLevel)
    }

    func mapDidMove(center: CLLocationCoordinate2D, zoomLevel: Double) {
        visibleCenter = center
        visibleZoomLevel = zoomLevel

        guard !(tripPlan != nil && activePanel == .trip) else { return }

        mapLoadTask?.cancel()
        mapLoadTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await self?.reloadPOIs(center: center, zoomLevel: zoomLevel)
        }
    }

    func select(place: Place) {
        selectedPlace = place
        activePanel = .places
    }

    func applyQuickPrompt(_ prompt: String) {
        queryText = prompt
    }

    func runSearch() async {
        let trimmedQuery = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        searchState = .loading
        do {
            let result = try await semanticSearchService.search(
                text: trimmedQuery,
                center: userCoordinate ?? visibleCenter
            )
            lastParsedQuery = result.parsedQuery
            places = result.places
            selectedPlace = result.places.first
            activePanel = .places
            searchState = .loaded(result.explanation)

            if result.parsedQuery.intent == .tripPlan {
                planTrip()
            }
        } catch {
            searchState = .failed(error.localizedDescription)
        }
    }

    func planTrip() {
        let query = lastParsedQuery ?? ParsedTravelQuery.defaultTripPlan()
        let plan = tripPlanningService.makePlan(
            from: places,
            query: query,
            start: userCoordinate ?? visibleCenter
        )

        tripPlan = plan
        selectedPlace = plan.stops.first?.place
        activePanel = .trip

        let plannedPlaces = plan.stops.map(\.place)
        if !plannedPlaces.isEmpty {
            places = plannedPlaces
        }
    }

    func toggleVoiceInput() async {
        if isVoiceRecording {
            speechInputManager.stop()
            return
        }

        do {
            try await speechInputManager.start()
        } catch {
            searchState = .failed(error.localizedDescription)
        }
    }

    func confirmCheckIn(_ prompt: CheckInPrompt) {
        let checkIn = CheckIn(
            id: UUID().uuidString,
            tripID: tripPlan?.id,
            place: prompt.stop.place,
            coordinate: userCoordinate ?? prompt.stop.place.coordinate,
            checkedInAt: Date(),
            source: .autoGeofence
        )
        checkIns.insert(checkIn, at: 0)
        pendingCheckIn = nil
        activePanel = .checkIns
    }

    func dismissCheckIn() {
        pendingCheckIn = nil
    }

    private func reloadPOIs(center: CLLocationCoordinate2D, zoomLevel: Double) async {
        do {
            let categories = ZoomPOIPolicy.categories(for: zoomLevel)
            let pois = try await semanticSearchService.loadPOIs(
                center: center,
                zoomLevel: zoomLevel,
                categories: categories
            )
            places = pois
            if selectedPlace == nil {
                selectedPlace = pois.first
            }
            if case .idle = searchState {
                searchState = .loaded(ZoomPOIPolicy.message(for: zoomLevel))
            }
        } catch {
            searchState = .failed(error.localizedDescription)
        }
    }

    private func bindManagers() {
        locationManager.$currentLocation
            .sink { [weak self] location in
                Task { @MainActor in
                    guard let self, let location else { return }
                    self.userCoordinate = location.coordinate
                    self.evaluateCheckIn(at: location.coordinate)
                }
            }
            .store(in: &cancellables)

        speechInputManager.$transcript
            .sink { [weak self] transcript in
                Task { @MainActor in
                    guard let self, self.isVoiceRecording else { return }
                    self.queryText = transcript
                }
            }
            .store(in: &cancellables)

        speechInputManager.$isRecording
            .sink { [weak self] isRecording in
                Task { @MainActor in
                    self?.isVoiceRecording = isRecording
                }
            }
            .store(in: &cancellables)
    }

    private func evaluateCheckIn(at coordinate: CLLocationCoordinate2D) {
        guard pendingCheckIn == nil else { return }

        pendingCheckIn = checkInDetector.promptIfNeeded(
            location: coordinate,
            plan: tripPlan,
            existingCheckIns: checkIns
        )
    }
}
