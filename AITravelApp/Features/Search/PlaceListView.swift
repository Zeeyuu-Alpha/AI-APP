import SwiftUI

struct PlaceListView: View {
    let places: [Place]
    let selectedPlace: Place?
    let onSelect: (Place) -> Void
    let onPlanTrip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(places.count) places")
                    .font(.headline)
                Spacer()
                Button(action: onPlanTrip) {
                    Label("Plan", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(places.count < 2)
            }

            if places.isEmpty {
                ContentUnavailableView(
                    "No places yet",
                    systemImage: "map",
                    description: Text("Zoom in or search with natural language.")
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(places) { place in
                            PlaceCardView(
                                place: place,
                                isSelected: place.id == selectedPlace?.id
                            )
                            .frame(width: 260)
                            .onTapGesture {
                                onSelect(place)
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
    }
}
