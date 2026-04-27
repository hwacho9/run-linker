import CoreLocation
import MapKit
import SwiftUI

struct RunRouteMapView: UIViewRepresentable {
    let routePoints: [RunRoutePoint]
    let currentLocation: CLLocationCoordinate2D?
    var followsUser = true

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = followsUser ? .follow : .none
        mapView.pointOfInterestFilter = .excludingAll
        mapView.isRotateEnabled = false
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let existingPolylines = mapView.overlays.filter { $0 is MKPolyline }
        mapView.removeOverlays(existingPolylines)

        let coordinates = routePoints.map(\.coordinate)
        if coordinates.count >= 2 {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
            mapView.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 72, left: 48, bottom: 72, right: 48),
                animated: true
            )
        } else if let currentLocation {
            let region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 700, longitudinalMeters: 700)
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(AppTheme.primary)
            renderer.lineWidth = 6
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
    }
}
