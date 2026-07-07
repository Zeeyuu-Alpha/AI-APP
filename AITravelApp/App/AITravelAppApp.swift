import SwiftUI

@main
struct AITravelAppApp: App {
    var body: some Scene {
        WindowGroup {
            TravelHomeScene()
        }
    }
}

private struct TravelHomeScene: View {
    @StateObject private var viewModel: TravelHomeViewModel

    init() {
        _viewModel = StateObject(wrappedValue: AppContainer.makeHomeViewModel())
    }

    var body: some View {
        TravelHomeView(viewModel: viewModel)
    }
}
