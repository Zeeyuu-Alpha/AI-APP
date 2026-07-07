import SwiftUI

struct HomeBottomPanel: View {
    @ObservedObject var viewModel: TravelHomeViewModel

    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(.secondary.opacity(0.35))
                .frame(width: 36, height: 4)

            Picker("Panel", selection: $viewModel.activePanel) {
                ForEach(TravelHomeViewModel.ActivePanel.allCases) { panel in
                    Text(panel.rawValue).tag(panel)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch viewModel.activePanel {
                case .places:
                    PlaceListView(
                        places: viewModel.places,
                        selectedPlace: viewModel.selectedPlace,
                        onSelect: viewModel.select(place:),
                        onPlanTrip: viewModel.planTrip
                    )
                case .trip:
                    TripPlanSheet(
                        plan: viewModel.tripPlan,
                        onPlanTrip: viewModel.planTrip
                    )
                case .checkIns:
                    CheckInHistoryView(checkIns: viewModel.checkIns)
                }
            }
            .frame(height: 238)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
    }
}
