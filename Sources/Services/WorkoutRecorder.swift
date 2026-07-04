import Foundation
import CoreLocation

enum WorkoutState: Equatable {
    case idle
    case recording
    case paused
    case completed
}

@Observable
final class WorkoutRecorder {
    var state: WorkoutState = .idle
    var elapsedSeconds: TimeInterval = 0
    var distance: Double = 0
    var calories: Double = 0
    var elevationGain: Double = 0
    var hasIncompleteWorkout: Bool = false
    var trackPoints: [TrackPointData] = []
    var sensorSamples: [SensorSampleData] = []
    var currentHeartRate: Int = 0

    private var timer: Timer?
    private var autoSaveTimer: Timer?
    private var lastLocationTimestamp: Date?
    private var lastAltitude: Double?

    struct TrackPointData {
        let timestamp: Date
        let latitude: Double
        let longitude: Double
        let altitude: Double?
        let speed: Double?
    }

    struct SensorSampleData {
        let timestamp: Date
        let value: Double
        let unit: String
    }

    init() {
        checkForIncompleteWorkout()
    }

    func start() {
        state = .recording
        elapsedSeconds = 0
        distance = 0
        calories = 0
        elevationGain = 0
        trackPoints = []
        sensorSamples = []
        lastAltitude = nil
        startTimer()
        startAutoSave()
    }

    func pause() {
        guard state == .recording else { return }
        state = .paused
        stopTimer()
        stopAutoSave()
    }

    func resume() {
        guard state == .paused else { return }
        state = .recording
        startTimer()
        startAutoSave()
    }

    func stop() {
        state = .completed
        stopTimer()
        stopAutoSave()
        hasIncompleteWorkout = false
        UserDefaults.standard.set(false, forKey: "hasIncompleteWorkout")
    }

    func addTrackPoint(_ point: TrackPointData) {
        guard state == .recording else { return }

        // Filter out jitter - require minimum 2m movement or 3 seconds between points
        if let last = trackPoints.last {
            let timeDelta = point.timestamp.timeIntervalSince(last.timestamp)
            let distDelta = calculateDistance(
                lat1: last.latitude, lon1: last.longitude,
                lat2: point.latitude, lon2: point.longitude
            )
            if timeDelta < 3.0 && distDelta < 2.0 { return }
        }

        if let last = trackPoints.last {
            let delta = calculateDistance(
                lat1: last.latitude, lon1: last.longitude,
                lat2: point.latitude, lon2: point.longitude
            )
            distance += delta
        }

        if let alt = point.altitude {
            if let prevAlt = lastAltitude {
                let delta = alt - prevAlt
                if delta > 1.0 { elevationGain += delta }
            }
            lastAltitude = alt
        }

        trackPoints.append(point)
        lastLocationTimestamp = point.timestamp
    }

    func addHeartRate(_ value: Double) {
        guard state == .recording else { return }
        currentHeartRate = Int(value)
        sensorSamples.append(SensorSampleData(timestamp: Date(), value: value, unit: "bpm"))
        calories = calculateCalories(hr: value)
    }

    func updateFromLocation(_ location: CLLocation) {
        let point = TrackPointData(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            speed: location.speed >= 0 ? location.speed : nil
        )
        addTrackPoint(point)
    }

    // MARK: - Private

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.persistIncompleteWorkout()
        }
    }

    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }

    private func persistIncompleteWorkout() {
        UserDefaults.standard.set(true, forKey: "hasIncompleteWorkout")
        UserDefaults.standard.set(elapsedSeconds, forKey: "incompleteDuration")
        UserDefaults.standard.set(distance, forKey: "incompleteDistance")
    }

    private func checkForIncompleteWorkout() {
        hasIncompleteWorkout = UserDefaults.standard.bool(forKey: "hasIncompleteWorkout")
    }

    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    private func calculateCalories(hr: Double) -> Double {
        let minutes = elapsedSeconds / 60.0
        // Rough estimate: calories ≈ (HR × duration_in_min × 0.001)
        // More accurate would use user weight and HR zones
        return hr * minutes * 0.001
    }
}
