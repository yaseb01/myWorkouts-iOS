import SwiftUI
import MapKit

struct MapTrackView: UIViewRepresentable {
    let trackPoints: [CLLocationCoordinate2D]
    var currentLocation: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update track overlay
        mapView.removeOverlays(mapView.overlays)

        if trackPoints.count >= 2 {
            let polyline = MKPolyline(coordinates: trackPoints, count: trackPoints.count)
            mapView.addOverlay(polyline)

            // Auto-center on first point if we just started
            if trackPoints.count == 2 {
                let region = MKCoordinateRegion(
                    center: trackPoints[0],
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
                mapView.setRegion(region, animated: true)
            }
        }

        // Update current position marker
        mapView.removeAnnotations(mapView.annotations.filter { $0 is CurrentPositionAnnotation })
        if let loc = currentLocation {
            let annotation = CurrentPositionAnnotation(coordinate: loc)
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is CurrentPositionAnnotation {
                let identifier = "currentPosition"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = false
                return view
            }
            return nil
        }
    }
}

class CurrentPositionAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

// MARK: - Static Map for workout history

struct StaticMapTrackView: UIViewRepresentable {
    let trackPoints: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        guard !trackPoints.isEmpty else { return }

        let polyline = MKPolyline(coordinates: trackPoints, count: trackPoints.count)
        mapView.addOverlay(polyline)

        let latSpan = (trackPoints.map(\.latitude).max()! - trackPoints.map(\.latitude).min()!) * 111_000 * 1.3
        let avgLat = trackPoints.map(\.latitude).reduce(0, +) / Double(trackPoints.count)
        let lonSpan = (trackPoints.map(\.longitude).max()! - trackPoints.map(\.longitude).min()!) * cos(avgLat * .pi / 180) * 111_000 * 1.3

        let region = mapView.regionThatFits(MKCoordinateRegion(
            center: trackPoints[trackPoints.count / 2],
            latitudinalMeters: max(500, latSpan),
            longitudinalMeters: max(500, lonSpan)
        ))
        mapView.setRegion(region, animated: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
