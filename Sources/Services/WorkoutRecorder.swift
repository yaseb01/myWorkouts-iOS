import Foundation
import CoreLocation

enum WorkoutState: Equatable {
    case idle
    case recording
    case paused
    case completed
}

@MainActor
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
    /// Wall-clock time at which the current recording session started.
    private(set) var startDate: Date?

    // Heart-rate statistics, maintained incrementally (O(1) per sample) so
    // views can read them on every render tick instead of re-aggregating the
    // full sample array. The zone bounds come from the workout setup
    // (custom range or intensity level).
    private(set) var heartRateValues: [Double] = []
    private(set) var hrSum: Double = 0
    private(set) var hrMin: Double = 0
    private(set) var hrMax: Double = 0
    private(set) var hrBelowZone = 0
    private(set) var hrInZone = 0
    private(set) var hrAboveZone = 0
    private(set) var hrInZoneSum: Double = 0
    private var hrZoneMin = Int.min
    private var hrZoneMax = Int.max

    private var timer: Timer?
    private var autoSaveTimer: Timer?
    private var lastLocationTimestamp: Date?
    private var lastAltitude: Double?

    // Elapsed time is derived from the wall clock: Timers do not fire while
    // the app is suspended, so incrementing a counter drifts and misses all
    // time spent in the background.
    private var baseElapsed: TimeInterval = 0
    private var segmentStart: Date?

    // Calories integrate the per-minute burn rate between HR samples (~1 Hz)
    // instead of recomputing the whole total from the latest HR value.
    private var lastHeartRate: Double = 0
    private var lastHeartRateTime: Date?

    private var userWeight: Double?
    private var userAge: Int?
    private var userGender: Gender?

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

    struct IncompleteWorkoutData {
        let date: Date
        let duration: TimeInterval
        let distance: Double
    }

    init() {
        self.hasIncompleteWorkout = UserDefaults.standard.bool(forKey: "hasIncompleteWorkout")
    }

    func start(weight: Double? = nil, age: Int? = nil, gender: Gender? = nil,
               zoneMin: Int? = nil, zoneMax: Int? = nil) {
        state = .recording
        elapsedSeconds = 0
        baseElapsed = 0
        segmentStart = nil
        startDate = Date()
        distance = 0
        calories = 0
        elevationGain = 0
        trackPoints = []
        sensorSamples = []
        lastAltitude = nil
        lastHeartRate = 0
        lastHeartRateTime = nil
        heartRateValues = []
        hrSum = 0
        hrMin = 0
        hrMax = 0
        hrBelowZone = 0
        hrInZone = 0
        hrAboveZone = 0
        hrInZoneSum = 0
        hrZoneMin = zoneMin ?? Int.min
        hrZoneMax = zoneMax ?? Int.max
        userWeight = weight
        userAge = age
        userGender = gender
        startTimer()
        startAutoSave()
    }

    func pause() {
        guard state == .recording else { return }
        state = .paused
        stopTimer()
        stopAutoSave()
        // Do not bill paused time to calories.
        lastHeartRateTime = nil
    }

    func resume() {
        guard state == .paused else { return }
        state = .recording
        startTimer()
        startAutoSave()
    }

    func stop() {
        stopTimer()
        stopAutoSave()
        state = .completed
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

            distance += distDelta
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

        let now = Date()
        if let lastTime = lastHeartRateTime, lastHeartRate > 0 {
            // Cap the interval so sensor dropouts do not inflate the total.
            let delta = min(now.timeIntervalSince(lastTime), 10)
            if delta > 0 {
                calories += caloriesPerMinute(hr: lastHeartRate) * delta / 60
            }
        }
        lastHeartRate = value
        lastHeartRateTime = now

        // Update the incremental statistics.
        heartRateValues.append(value)
        hrSum += value
        if heartRateValues.count == 1 {
            hrMin = value
            hrMax = value
        } else {
            hrMin = min(hrMin, value)
            hrMax = max(hrMax, value)
        }
        let hr = Int(value)
        if hr < hrZoneMin {
            hrBelowZone += 1
        } else if hr <= hrZoneMax {
            hrInZone += 1
            hrInZoneSum += value
        } else {
            hrAboveZone += 1
        }

        sensorSamples.append(SensorSampleData(timestamp: now, value: value, unit: "bpm"))
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

    // MARK: - Incomplete Workout Recovery

    /// Returns the persisted data of a workout that was interrupted by a
    /// crash or force-quit, or nil when there is nothing worth recovering.
    func readIncompleteWorkout() -> IncompleteWorkoutData? {
        guard hasIncompleteWorkout else { return nil }
        let defaults = UserDefaults.standard
        let duration = defaults.double(forKey: "incompleteDuration")
        // Ignore recordings that never really started.
        guard duration >= 5 else {
            clearIncompleteWorkout()
            return nil
        }
        return IncompleteWorkoutData(
            date: defaults.object(forKey: "incompleteDate") as? Date ?? Date(),
            duration: duration,
            distance: defaults.double(forKey: "incompleteDistance")
        )
    }

    func clearIncompleteWorkout() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasIncompleteWorkout")
        defaults.removeObject(forKey: "incompleteDuration")
        defaults.removeObject(forKey: "incompleteDistance")
        defaults.removeObject(forKey: "incompleteDate")
        hasIncompleteWorkout = false
    }

    // MARK: - Private

    private func startTimer() {
        segmentStart = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let segmentStart = self.segmentStart else { return }
                self.elapsedSeconds = self.baseElapsed + Date().timeIntervalSince(segmentStart)
            }
        }
    }

    private func stopTimer() {
        if let segmentStart = segmentStart {
            baseElapsed += Date().timeIntervalSince(segmentStart)
            self.segmentStart = nil
        }
        elapsedSeconds = baseElapsed
        timer?.invalidate()
        timer = nil
    }

    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.persistIncompleteWorkout()
            }
        }
    }

    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }

    private func persistIncompleteWorkout() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "hasIncompleteWorkout")
        defaults.set(elapsedSeconds, forKey: "incompleteDuration")
        defaults.set(distance, forKey: "incompleteDistance")
        defaults.set(Date(), forKey: "incompleteDate")
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

    /// Heart-rate based burn rate in kcal/minute (Keytel-style formula).
    private func caloriesPerMinute(hr: Double) -> Double {
        guard let weight = userWeight, let age = userAge else {
            // Rough fallback when no profile data is available.
            return max(0, hr * 0.01)
        }
        guard hr > 0 else { return 0 }

        if userGender == .female {
            return max(0, (0.4472 * hr + 0.1263 * weight + 0.074 * Double(age) - 20.4022) / 4.184)
        } else {
            return max(0, (0.6309 * hr + 0.1988 * weight + 0.2017 * Double(age) - 55.0969) / 4.184)
        }
    }
}
