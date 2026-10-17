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
        let coordinator = context.coordinator

        if trackPoints.count >= 2 {
            // Rebuild the overlay only when new points arrived - not on
            // every SwiftUI update (timer ticks, position marker moves).
            if trackPoints.count != coordinator.lastPointCount {
                mapView.removeOverlays(mapView.overlays)
                let polyline = MKPolyline(coordinates: trackPoints, count: trackPoints.count)
                mapView.addOverlay(polyline)
                coordinator.lastPointCount = trackPoints.count
            }

            // Center on the first point once the track exists. The jitter
            // filter can make the point count jump 1 -> 3, so a fixed
            // count check would never trigger.
            if !coordinator.hasCenteredOnTrack {
                coordinator.hasCenteredOnTrack = true
                let region = MKCoordinateRegion(
                    center: trackPoints[0],
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
                mapView.setRegion(region, animated: true)
            }
        } else {
            if coordinator.lastPointCount != 0 {
                mapView.removeOverlays(mapView.overlays)
                coordinator.lastPointCount = 0
            }
            coordinator.hasCenteredOnTrack = false
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
        var lastPointCount = 0
        var hasCenteredOnTrack = false

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
        // Skip redundant updates - the track data of a saved workout rarely
        // changes, but SwiftUI still calls updateUIView on every re-render.
        let signature = trackSignature
        if context.coordinator.lastSignature == signature { return }
        context.coordinator.lastSignature = signature

        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        guard !trackPoints.isEmpty else { return }

        let polyline = MKPolyline(coordinates: trackPoints, count: trackPoints.count)
        mapView.addOverlay(polyline)

        // Fit the whole track: geographic center plus generous padding.
        let lats = trackPoints.map(\.latitude)
        let lons = trackPoints.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let latSpan = (lats.max()! - lats.min()!) * 111_000 * 1.3
        let lonSpan = (lons.max()! - lons.min()!) * cos(center.latitude * .pi / 180) * 111_000 * 1.3

        let region = mapView.regionThatFits(MKCoordinateRegion(
            center: center,
            latitudinalMeters: max(500, latSpan),
            longitudinalMeters: max(500, lonSpan)
        ))
        mapView.setRegion(region, animated: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private var trackSignature: TrackSignature? {
        guard let first = trackPoints.first, let last = trackPoints.last else { return nil }
        return TrackSignature(count: trackPoints.count,
                              firstLat: first.latitude, firstLon: first.longitude,
                              lastLat: last.latitude, lastLon: last.longitude)
    }

    struct TrackSignature: Equatable {
        let count: Int
        let firstLat: Double
        let firstLon: Double
        let lastLat: Double
        let lastLon: Double
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var lastSignature: TrackSignature?

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
