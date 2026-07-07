import SwiftUI

struct PlaceCardView: View {
    let place: Place
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: place.category.symbolName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(categoryColor.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(place.category.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            Text(place.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack(spacing: 10) {
                if let rating = place.rating {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                }
                if let priceLevel = place.priceLevel {
                    Label(priceText(for: priceLevel), systemImage: "creditcard.fill")
                }
                if place.isOpenNow == true {
                    Label("Open", systemImage: "clock.fill")
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(isSelected ? Color.blue.opacity(0.14) : Color(.secondarySystemBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var categoryColor: Color {
        switch place.category {
        case .attraction: return .red
        case .restaurant: return .orange
        case .cafe: return .brown
        case .hotel: return .indigo
        case .shopping: return .purple
        case .viewpoint: return .pink
        case .museum: return .blue
        case .park: return .green
        case .bar: return .teal
        case .transport: return .gray
        }
    }

    private func priceText(for level: Int) -> String {
        guard level > 0 else { return "Free" }
        return String(repeating: "$", count: min(level, 4))
    }
}
