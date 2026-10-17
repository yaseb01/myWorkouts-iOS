import XCTest
import SwiftData
@testable import myWorkouts

@MainActor
final class myWorkoutsIntegrationTests: XCTestCase {

    // MARK: - ModelContainer Registration

    func testModelContainerRegistersAllModels() throws {
        let schema = Schema([
            Workout.self,
            TrackPoint.self,
            SensorSample.self,
            Goal.self,
            SportType.self,
            HeartRateZone.self,
            UserProfile.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        XCTAssertNotNil(container)
        XCTAssertNotNil(container.mainContext)
    }

    func testAppModelContainerIncludesAllModels() throws {
        let schema = Schema([
            Workout.self,
            TrackPoint.self,
            SensorSample.self,
            Goal.self,
            SportType.self,
            HeartRateZone.self,
            UserProfile.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        XCTAssertNotNil(container.mainContext, "Schema-based ModelContainer must provide a mainContext")
    }

    // MARK: - Service Initialization

    func testLocationManagerCanBeCreated() throws {
        let locationManager = LocationManager()
        XCTAssertNotNil(locationManager, "LocationManager must be initializable")
    }

    func testSensorManagerCanBeCreated() throws {
        let sensorManager = SensorManager()
        XCTAssertNotNil(sensorManager, "SensorManager must be initializable")
    }

    func testWorkoutRecorderCanBeCreated() throws {
        let recorder = WorkoutRecorder()
        XCTAssertNotNil(recorder, "WorkoutRecorder must be initializable")
        XCTAssertEqual(recorder.state, .idle, "WorkoutRecorder must start in idle state")
    }

    func testWorkoutRecorderStateTransitions() throws {
        let recorder = WorkoutRecorder()
        XCTAssertEqual(recorder.state, .idle)

        recorder.start()
        XCTAssertEqual(recorder.state, .recording, "start() transitions idle → recording")

        recorder.pause()
        XCTAssertEqual(recorder.state, .paused, "pause() transitions recording → paused")

        recorder.resume()
        XCTAssertEqual(recorder.state, .recording, "resume() transitions paused → recording")

        recorder.stop()
        XCTAssertEqual(recorder.state, .completed, "stop() transitions recording → completed")
    }

    // MARK: - Incremental Heart-Rate Statistics

    func testWorkoutRecorderHeartRateStats() throws {
        let recorder = WorkoutRecorder()
        recorder.start(zoneMin: 100, zoneMax: 150)
        defer { recorder.stop() }

        recorder.addHeartRate(90)   // below zone
        recorder.addHeartRate(120)  // in zone
        recorder.addHeartRate(160)  // above zone

        XCTAssertEqual(recorder.heartRateValues.count, 3)
        XCTAssertEqual(recorder.hrMin, 90)
        XCTAssertEqual(recorder.hrMax, 160)
        XCTAssertEqual(recorder.hrSum, 370)
        XCTAssertEqual(recorder.hrBelowZone, 1)
        XCTAssertEqual(recorder.hrInZone, 1)
        XCTAssertEqual(recorder.hrAboveZone, 1)
        XCTAssertEqual(recorder.hrInZoneSum, 120)
    }

    func testWorkoutRecorderHeartRateStatsResetOnStart() throws {
        let recorder = WorkoutRecorder()
        recorder.start(zoneMin: 100, zoneMax: 150)
        recorder.addHeartRate(120)
        recorder.stop()

        recorder.start()
        XCTAssertEqual(recorder.heartRateValues.count, 0)
        XCTAssertEqual(recorder.hrSum, 0)
        XCTAssertEqual(recorder.hrMin, 0)
        XCTAssertEqual(recorder.hrMax, 0)
        XCTAssertEqual(recorder.hrInZone, 0)
        recorder.stop()
    }

    // MARK: - Calorie Integration

    func testWorkoutRecorderCalorieIntegration() throws {
        let recorder = WorkoutRecorder()
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        recorder.start(weight: 70, age: 30, gender: .male)
        defer { recorder.stop() }

        let perMinute = { (hr: Double) in
            (0.6309 * hr + 0.1988 * 70 + 0.2017 * 30 - 55.0969) / 4.184
        }

        // First sample only anchors the integration window.
        recorder.addHeartRate(120, at: t0)
        XCTAssertEqual(recorder.calories, 0, accuracy: 0.0001)

        // Samples at the realistic ~1 Hz spacing must accumulate.
        recorder.addHeartRate(120, at: t0.addingTimeInterval(5))
        XCTAssertEqual(recorder.calories, perMinute(120) * 5 / 60, accuracy: 0.001)

        // A long sensor dropout is capped at 10 billed seconds, billed at the
        // previous sample's heart rate - a lower HR must not erase calories
        // already earned either.
        recorder.addHeartRate(100, at: t0.addingTimeInterval(1000))
        XCTAssertEqual(recorder.calories,
                       perMinute(120) * 15 / 60,
                       accuracy: 0.001)
    }

    // MARK: - GPX Round Trip

    func testGPXExportImportRoundTrip() throws {
        let sport = SportType(name: "Strength & Conditioning", abbreviation: "S&C")
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let workout = Workout(sportType: sport, startTime: start, duration: 20)

        let coords: [(Double, Double, Double)] = [
            (52.5200, 13.4050, 42.0),
            (52.5210, 13.4060, 45.5),
            (52.5220, 13.4070, 44.0)
        ]
        for (i, c) in coords.enumerated() {
            let tp = TrackPoint(
                timestamp: start.addingTimeInterval(TimeInterval(i * 10)),
                latitude: c.0, longitude: c.1, altitude: c.2
            )
            tp.workout = workout
            workout.trackPoints.append(tp)
        }

        let data = try XCTUnwrap(GPXManager.exportWorkout(workout),
            "Export must produce data for a workout with track points")

        let parsed = try XCTUnwrap(GPXManager.importGPX(from: data),
            "Exported GPX with '&' in the sport name must still parse (XML escaping)")

        XCTAssertEqual(parsed.trackPoints.count, 3)
        XCTAssertEqual(parsed.trackPoints[0].latitude, 52.5200, accuracy: 1e-9)
        XCTAssertEqual(parsed.trackPoints[0].longitude, 13.4050, accuracy: 1e-9)
        XCTAssertEqual(parsed.trackPoints[2].latitude, 52.5220, accuracy: 1e-9)
        XCTAssertEqual(parsed.trackPoints[1].altitude ?? 0, 45.5, accuracy: 0.01)
        XCTAssertEqual(parsed.trackPoints[1].timestamp?.timeIntervalSince1970 ?? 0,
                       start.addingTimeInterval(10).timeIntervalSince1970, accuracy: 0.5)
        XCTAssertTrue(parsed.name?.contains("Strength & Conditioning") == true)
    }

    // MARK: - Crash Recovery

    func testWorkoutRecorderDetectsIncompleteWorkout() throws {
        let recorder = WorkoutRecorder()
        XCTAssertFalse(recorder.hasIncompleteWorkout, "No incomplete workout on fresh init")
    }

    // MARK: - Accessibility

    func testContentViewTabAccessibilityLabels() throws {
        let contentView = ContentView()
        // Verify the tab enum produces correct accessibility identifiers
        XCTAssertEqual(contentView.tabIdentifiers.count, 5, "Must have 5 tabs")
        XCTAssertTrue(contentView.tabIdentifiers.contains("home"))
        XCTAssertTrue(contentView.tabIdentifiers.contains("record"))
        XCTAssertTrue(contentView.tabIdentifiers.contains("history"))
        XCTAssertTrue(contentView.tabIdentifiers.contains("analysis"))
        XCTAssertTrue(contentView.tabIdentifiers.contains("settings"))
    }
}
