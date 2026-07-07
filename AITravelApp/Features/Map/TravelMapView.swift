import MapKit
import SwiftUI
import UIKit

struct TravelMapView: UIViewRepresentable {
    let places: [Place]
    let selectedPlace: Place?
    let routeCoordinates: [CLLocationCoordinate2D]
    let onSelectPlace: (Place) -> Void
    let onViewportChange: (CLLocationCoordinate2D, Double) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsBuildings = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.pointOfInterestFilter = .includingAll
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic)

        let paris = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        let camera = MKMapCamera(
            lookingAtCenter: paris,
            fromDistance: 4_500,
            pitch: 58,
            heading: 18
        )
        mapView.setCamera(camera, animated: false)
        context.coordinator.didSetInitialCamera = true

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateAnnotations(on: mapView, places: places, selectedPlace: selectedPlace)
        context.coordinator.updateRoute(on: mapView, routeCoordinates: routeCoordinates)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TravelMapView
        var didSetInitialCamera = false
        private var routeSignature = ""

        init(parent: TravelMapView) {
            self.parent = parent
        }

        func updateAnnotations(
            on mapView: MKMapView,
            places: [Place],
            selectedPlace: Place?
        ) {
            let currentAnnotations = mapView.annotations.compactMap { $0 as? PlaceMapAnnotation }
            mapView.removeAnnotations(currentAnnotations)

            let annotations = places.map(PlaceMapAnnotation.init(place:))
            mapView.addAnnotations(annotations)

            guard let selectedPlace else { return }
            if let selectedAnnotation = annotations.first(where: { $0.place.id == selectedPlace.id }) {
                mapView.selectAnnotation(selectedAnnotation, animated: true)
            }
        }

        func updateRoute(
            on mapView: MKMapView,
            routeCoordinates: [CLLocationCoordinate2D]
        ) {
            let signature = routeCoordinates
                .map { "\($0.latitude.rounded(toPlaces: 5)),\($0.longitude.rounded(toPlaces: 5))" }
                .joined(separator: "|")

            guard signature != routeSignature else { return }
            routeSignature = signature

            mapView.removeOverlays(mapView.overlays)

            guard routeCoordinates.count > 1 else { return }
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(polyline)
            mapView.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 140, left: 48, bottom: 360, right: 48),
                animated: true
            )
        }

        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            guard let annotation = annotation as? PlaceMapAnnotation else { return }
            parent.onSelectPlace(annotation.place)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let zoom = zoomLevel(for: mapView)
            parent.onViewportChange(mapView.centerCoordinate, zoom)
        }

        func mapView(
            _ mapView: MKMapView,
            viewFor annotation: MKAnnotation
        ) -> MKAnnotationView? {
            guard let annotation = annotation as? PlaceMapAnnotation else {
                return nil
            }

            let identifier = "PlaceMapAnnotation"
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier
            ) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )

            view.annotation = annotation
            view.canShowCallout = true
            view.markerTintColor = tintColor(for: annotation.place.category)
            view.glyphImage = UIImage(systemName: annotation.place.category.symbolName)
            view.titleVisibility = .adaptive
            view.subtitleVisibility = .adaptive
            return view
        }

        func mapView(
            _ mapView: MKMapView,
            rendererFor overlay: MKOverlay
        ) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.86)
            renderer.lineWidth = 5
            renderer.lineJoin = .round
            renderer.lineCap = .round
            return renderer
        }

        private func zoomLevel(for mapView: MKMapView) -> Double {
            let longitudeDelta = mapView.region.span.longitudeDelta
            let mapWidth = Double(mapView.bounds.width)
            guard longitudeDelta > 0, mapWidth > 0 else { return 13 }
            return log2(360 * (mapWidth / 256) / longitudeDelta)
        }

        private func tintColor(for category: PlaceCategory) -> UIColor {
            switch category {
            case .attraction: return .systemRed
            case .restaurant: return .systemOrange
            case .cafe: return .systemBrown
            case .hotel: return .systemIndigo
            case .shopping: return .systemPurple
            case .viewpoint: return .systemPink
            case .museum: return .systemBlue
            case .park: return .systemGreen
            case .bar: return .systemTeal
            case .transport: return .systemGray
            }
        }
    }
}

private final class PlaceMapAnnotation: NSObject, MKAnnotation {
    let place: Place

    var coordinate: CLLocationCoordinate2D {
        place.coordinate
    }

    var title: String? {
        place.name
    }

    var subtitle: String? {
        place.category.title
    }

    init(place: Place) {
        self.place = place
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
