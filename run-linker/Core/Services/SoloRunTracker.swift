import Combine
import CoreLocation
import Foundation

struct RunRoutePoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

protocol RunTrackingServiceProtocol: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var routePoints: [RunRoutePoint] { get }
    var currentLocation: CLLocationCoordinate2D? { get }
    var totalDistance: Double { get }
    var elapsedTime: TimeInterval { get }
    var currentPace: Int { get }
    var isTracking: Bool { get }
    var isPaused: Bool { get }
    var locationErrorMessage: String? { get }

    func start()
    func pause()
    func resume()
    func stop()
}

@MainActor
final class SoloRunTracker: NSObject, ObservableObject, RunTrackingServiceProtocol {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var routePoints: [RunRoutePoint] = []
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var totalDistance: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentPace: Int = 0
    @Published var isTracking = false
    @Published var isPaused = false
    @Published var locationErrorMessage: String?

    private let locationManager = CLLocationManager()
    private var lastAcceptedLocation: CLLocation?
    private var startedAt: Date?
    private var accumulatedPausedTime: TimeInterval = 0
    private var pausedAt: Date?
    private var timer: Timer?

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 3
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    var distanceKilometers: Double {
        totalDistance / 1000
    }

    var formattedPace: String {
        guard currentPace > 0 else { return "--'--\"" }
        return String(format: "%d'%02d\"", currentPace / 60, currentPace % 60)
    }

    var formattedTime: String {
        let totalSeconds = Int(elapsedTime)
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    func start() {
        guard !isTracking else { return }

        routePoints.removeAll()
        currentLocation = nil
        totalDistance = 0
        elapsedTime = 0
        currentPace = 0
        locationErrorMessage = nil
        lastAcceptedLocation = nil
        startedAt = Date()
        accumulatedPausedTime = 0
        pausedAt = nil
        isTracking = true
        isPaused = false

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            beginLocationUpdates()
        case .denied, .restricted:
            locationErrorMessage = String(localized: "run_tracking.location_permission_denied")
            startTimer()
        @unknown default:
            locationErrorMessage = String(localized: "run_tracking.location_permission_unknown")
            startTimer()
        }
    }

    func pause() {
        guard isTracking, !isPaused else { return }
        isPaused = true
        pausedAt = Date()
        locationManager.stopUpdatingLocation()
    }

    func resume() {
        guard isTracking, isPaused else { return }
        if let pausedAt {
            accumulatedPausedTime += Date().timeIntervalSince(pausedAt)
        }
        self.pausedAt = nil
        isPaused = false
        lastAcceptedLocation = nil
        beginLocationUpdates()
    }

    func stop() {
        isTracking = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        locationManager.stopUpdatingLocation()
        updateElapsedTime()
    }

    private func beginLocationUpdates() {
        startTimer()
        locationManager.startUpdatingLocation()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let tracker = self, tracker.isTracking, !tracker.isPaused else { return }
                tracker.updateElapsedTime()
            }
        }
    }

    private func updateElapsedTime() {
        guard let startedAt else { return }
        let pausedDuration = isPaused ? Date().timeIntervalSince(pausedAt ?? Date()) : 0
        elapsedTime = max(0, Date().timeIntervalSince(startedAt) - accumulatedPausedTime - pausedDuration)
        updatePace()
    }

    private func acceptLocation(_ location: CLLocation) {
        guard isTracking, !isPaused else { return }
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 40 else { return }

        currentLocation = location.coordinate

        if let lastAcceptedLocation {
            let delta = location.distance(from: lastAcceptedLocation)
            if delta >= 1, delta < 100 {
                totalDistance += delta
            }
        }

        lastAcceptedLocation = location
        routePoints.append(
            RunRoutePoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: location.timestamp
            )
        )
        updateElapsedTime()
    }

    private func updatePace() {
        guard totalDistance > 0 else {
            currentPace = 0
            return
        }
        currentPace = Int((elapsedTime / totalDistance) * 1000)
    }
}

extension SoloRunTracker: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if isTracking, authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                beginLocationUpdates()
            } else if authorizationStatus == .denied || authorizationStatus == .restricted {
                locationErrorMessage = String(localized: "run_tracking.location_permission_denied")
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locations.forEach(acceptLocation)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationErrorMessage = error.localizedDescription
        }
    }
}
