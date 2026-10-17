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
