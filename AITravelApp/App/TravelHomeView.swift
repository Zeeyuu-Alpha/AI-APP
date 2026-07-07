import SwiftUI

struct TravelHomeView: View {
    @StateObject private var viewModel: TravelHomeViewModel

    init(viewModel: TravelHomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TravelMapView(
                places: viewModel.places,
                selectedPlace: viewModel.selectedPlace,
                routeCoordinates: viewModel.tripPlan?.routeCoordinates ?? [],
                onSelectPlace: viewModel.select(place:),
                onViewportChange: viewModel.mapDidMove(center:zoomLevel:)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                SearchHeaderView(
                    queryText: $viewModel.queryText,
                    searchState: viewModel.searchState,
                    isVoiceRecording: viewModel.isVoiceRecording,
                    onSearch: {
                        Task { await viewModel.runSearch() }
                    },
                    onVoice: {
                        Task { await viewModel.toggleVoiceInput() }
                    },
                    onQuickPrompt: { prompt in
                        viewModel.applyQuickPrompt(prompt)
                        Task { await viewModel.runSearch() }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                HomeBottomPanel(viewModel: viewModel)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
        }
        .task {
            await viewModel.bootstrap()
        }
        .alert(item: $viewModel.pendingCheckIn) { prompt in
            Alert(
                title: Text("Arrived at \(prompt.stop.place.name)"),
                message: Text("You are within \(Int(prompt.distanceMeters)) m. Add a check-in?"),
                primaryButton: .default(Text("Check in")) {
                    viewModel.confirmCheckIn(prompt)
                },
                secondaryButton: .cancel {
                    viewModel.dismissCheckIn()
                }
            )
        }
    }
}
