import SwiftUI

struct CheckInHistoryView: View {
    let checkIns: [CheckIn]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(checkIns.count) check-ins")
                .font(.headline)

            if checkIns.isEmpty {
                ContentUnavailableView(
                    "No check-ins",
                    systemImage: "checkmark.seal",
                    description: Text("Arrive near a planned stop to check in.")
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(checkIns) { checkIn in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(checkIn.place.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(checkIn.checkedInAt, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(checkIn.source.rawValue)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
    }
}
