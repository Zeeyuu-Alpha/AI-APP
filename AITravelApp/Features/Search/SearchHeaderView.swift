import SwiftUI

struct SearchHeaderView: View {
    @Binding var queryText: String
    let searchState: TravelHomeViewModel.SearchState
    let isVoiceRecording: Bool
    let onSearch: () -> Void
    let onVoice: () -> Void
    let onQuickPrompt: (String) -> Void

    private let quickPrompts = [
        "Photo-friendly restaurants nearby",
        "Plan a relaxed half-day classic route with lunch",
        "Find local hidden gems that are not too expensive"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)

                TextField("Ask for places or a route", text: $queryText, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit(onSearch)

                Button(action: onVoice) {
                    Image(systemName: isVoiceRecording ? "mic.circle.fill" : "mic.circle")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(isVoiceRecording ? .red : .primary)
                }
                .buttonStyle(.plain)

                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button {
                            onQuickPrompt(prompt)
                        } label: {
                            Text(prompt)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            statusView
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch searchState {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Searching")
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        case .loaded(let message):
            Text(message)
                .font(.caption)
                .lineLimit(2)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        case .failed(let message):
            Text(message)
                .font(.caption.weight(.medium))
                .foregroundStyle(.red)
                .lineLimit(2)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
