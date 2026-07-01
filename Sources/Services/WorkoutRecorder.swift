import Foundation

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

    private var timer: Timer?

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
        startTimer()
    }

    func pause() {
        guard state == .recording else { return }
        state = .paused
        stopTimer()
    }

    func resume() {
        guard state == .paused else { return }
        state = .recording
        startTimer()
    }

    func stop() {
        state = .completed
        stopTimer()
        hasIncompleteWorkout = false
    }

    func addTrackPoint(_ point: TrackPointData) {
        guard state == .recording else { return }
        if let last = trackPoints.last {
            let delta = calculateDistance(lat1: last.latitude, lon1: last.longitude,
                                         lat2: point.latitude, lon2: point.longitude)
            distance += delta
        }
        if let alt = point.altitude, let lastAlt = trackPoints.last?.altitude {
            let delta = alt - lastAlt
            if delta > 0 { elevationGain += delta }
        }
        trackPoints.append(point)
    }

    func addHeartRate(_ value: Double) {
        guard state == .recording else { return }
        sensorSamples.append(SensorSampleData(timestamp: Date(), value: value, unit: "bpm"))
        calories = calculateCalories(hr: value)
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

    private func checkForIncompleteWorkout() {
        // Check UserDefaults or disk for persisted incomplete workout state
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
        // Simplified calorie estimate based on heart rate and duration
        let minutes = elapsedSeconds / 60.0
        return (hr * minutes * 0.001) // placeholder formula
    }
}
