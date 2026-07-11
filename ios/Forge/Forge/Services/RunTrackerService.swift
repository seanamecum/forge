import Foundation
import CoreLocation
import Observation

/// Pure run math — separated from CoreLocation so it's unit-testable.
enum RunMath {
    /// Seconds per kilometer; nil until there's meaningful movement.
    static func paceSecPerKm(meters: Double, seconds: Double) -> Double? {
        guard meters > 25, seconds > 5 else { return nil }
        return seconds / (meters / 1000)
    }

    /// "8'42\"" style pace label for the athlete's unit system.
    static func paceLabel(secPerKm: Double?, imperial: Bool) -> String {
        guard let secPerKm else { return "—'——\"" }
        let sec = imperial ? secPerKm * 1.609344 : secPerKm
        let m = Int(sec) / 60, s = Int(sec) % 60
        return "\(m)'\(String(format: "%02d", s))\""
    }

    static func distanceLabel(meters: Double, imperial: Bool) -> String {
        imperial ? String(format: "%.2f", meters / 1609.344)
                 : String(format: "%.2f", meters / 1000)
    }

    /// Reject GPS noise: bad accuracy, teleports, or stale points.
    static func isUsable(accuracy: Double, jumpMeters: Double, dt: Double) -> Bool {
        accuracy > 0 && accuracy <= 35 && dt > 0 && (jumpMeters / dt) <= 12.5   // ≤ 45 km/h
    }
}

/// Real GPS run tracking via CoreLocation — live distance, pace, splits, route.
/// Foreground tracking (background mode is a paid-capability follow-up).
@Observable
final class RunTrackerService: NSObject, CLLocationManagerDelegate {

    enum State: Equatable { case idle, tracking, paused, finished }

    var state: State = .idle
    var authorization: CLAuthorizationStatus = .notDetermined
    var route: [CLLocationCoordinate2D] = []
    var distanceMeters: Double = 0
    var elapsedSeconds: Double = 0
    /// Split length in meters — 1609.344 (mile) for imperial athletes, 1000 otherwise.
    var splitLengthMeters: Double = 1609.344
    var splitsSecPerKm: [Double] = []
    var lastError: String?

    var paceSecPerKm: Double? { RunMath.paceSecPerKm(meters: distanceMeters, seconds: elapsedSeconds) }
    var startedAt: Date?

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var segmentStart: Date?
    private var accumulated: TimeInterval = 0
    private var lastSplitMark: Double = 0
    private var lastSplitTime: TimeInterval = 0
    private var ticker: Timer?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 5
        authorization = manager.authorizationStatus
    }

    // MARK: - Controls

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        guard authorization == .authorizedWhenInUse || authorization == .authorizedAlways else {
            requestPermission(); return
        }
        route = []; distanceMeters = 0; elapsedSeconds = 0; splitsSecPerKm = []
        accumulated = 0; lastSplitMark = 0; lastSplitTime = 0
        lastLocation = nil; lastError = nil
        startedAt = .now; segmentStart = .now
        state = .tracking
        manager.startUpdatingLocation()
        startTicker()
    }

    func pause() {
        guard state == .tracking else { return }
        accumulated += Date.now.timeIntervalSince(segmentStart ?? .now)
        segmentStart = nil
        manager.stopUpdatingLocation()
        lastLocation = nil          // don't draw a line across the pause
        state = .paused
        ticker?.invalidate()
    }

    func resume() {
        guard state == .paused else { return }
        segmentStart = .now
        state = .tracking
        manager.startUpdatingLocation()
        startTicker()
    }

    func stop() {
        if state == .tracking { accumulated += Date.now.timeIntervalSince(segmentStart ?? .now) }
        manager.stopUpdatingLocation()
        ticker?.invalidate()
        elapsedSeconds = accumulated
        state = .finished
    }

    func reset() { state = .idle }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.state == .tracking else { return }
            self.elapsedSeconds = self.accumulated + Date.now.timeIntervalSince(self.segmentStart ?? .now)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .denied {
            lastError = "Location access denied. Enable it in Settings → Privacy → Location Services → Forge."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard state == .tracking else { return }
        for location in locations {
            if let last = lastLocation {
                let jump = location.distance(from: last)
                let dt = location.timestamp.timeIntervalSince(last.timestamp)
                guard RunMath.isUsable(accuracy: location.horizontalAccuracy, jumpMeters: jump, dt: dt)
                else { continue }
                distanceMeters += jump
                // Close a split every mile (imperial) or kilometer.
                if distanceMeters - lastSplitMark >= splitLengthMeters {
                    splitsSecPerKm.append(elapsedSeconds - lastSplitTime)
                    lastSplitMark += splitLengthMeters
                    lastSplitTime = elapsedSeconds
                }
            } else if !RunMath.isUsable(accuracy: location.horizontalAccuracy, jumpMeters: 0, dt: 1) {
                continue
            }
            lastLocation = location
            route.append(location.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = "GPS: \(error.localizedDescription)"
    }
}
