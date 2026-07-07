import SwiftUI

struct TripPlanSheet: View {
    let plan: TripPlan?
    let onPlanTrip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let plan {
                header(plan)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(plan.stops) { stop in
                            TripStopRow(stop: stop)
                        }
                    }
                    .padding(.bottom, 4)
                }
            } else {
                ContentUnavailableView(
                    "No trip plan",
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                    description: Text("Search or use current places to create a route.")
                )
                Button(action: onPlanTrip) {
                    Label("Create Plan", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
                .disabled(true)
            }
        }
    }

    private func header(_ plan: TripPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.title)
                    .font(.headline)
                Spacer()
                Label(plan.travelMode.title, systemImage: "figure.walk")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 14) {
                Label("\(plan.totalDurationMinutes) min", systemImage: "clock")
                Label(String(format: "%.1f km", plan.totalDistanceMeters / 1_000), systemImage: "map")
                Label("\(plan.stops.count) stops", systemImage: "mappin.and.ellipse")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
    }
}

private struct TripStopRow: View {
    let stop: TripStop

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(stop.order)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stop.place.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text("+\(stop.arrivalOffsetMinutes)m")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Text(stop.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Label("\(stop.stayMinutes) min stay", systemImage: stop.place.category.symbolName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
