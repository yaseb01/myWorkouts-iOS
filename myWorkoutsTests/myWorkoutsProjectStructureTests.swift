import XCTest
import SwiftData
@testable import myWorkouts

/// Verifies that the Xcode project compiles with all expected source files included.
/// Each test confirms a type from a specific source folder exists, proving the file
/// is part of the build target and the folder structure is correct.
@MainActor
final class myWorkoutsProjectStructureTests: XCTestCase {

    // MARK: - App

    func testAppEntryPointExists() throws {
        let app = myWorkoutsApp()
        XCTAssertNotNil(app, "myWorkoutsApp must exist and be initializable")
    }

    func testContentViewExists() throws {
        let content = ContentView()
        XCTAssertEqual(content.tabCount, 5)
    }

    // MARK: - Models

    func testWorkoutModelExists() throws {
        let workout = Workout()
        XCTAssertNotNil(workout.id)
        XCTAssertEqual(workout.duration, 0)
    }

    func testTrackPointModelExists() throws {
        let tp = TrackPoint(latitude: 48.0, longitude: 11.0)
        XCTAssertEqual(tp.latitude, 48.0)
        XCTAssertEqual(tp.longitude, 11.0)
    }

    func testSensorSampleModelExists() throws {
        let sample = SensorSample(type: .heartRate, value: 140, unit: "bpm")
        XCTAssertEqual(sample.value, 140)
    }

    func testGoalModelExists() throws {
        let goal = Goal(type: .distance, weeklyTarget: 50)
        XCTAssertEqual(goal.weeklyTarget, 50)
        XCTAssertTrue(goal.isActive)
    }

    func testSportTypeModelExists() throws {
        let sport = SportType(name: "Running", abbreviation: "RUN")
        XCTAssertEqual(sport.name, "Running")
    }

    func testHeartRateZoneModelExists() throws {
        let zone = HeartRateZone(name: "Tempo", minHR: 133, maxHR: 152, zoneNumber: 3)
        XCTAssertEqual(zone.zoneNumber, 3)
    }

    func testUserProfileModelExists() throws {
        let profile = UserProfile(weight: 75, height: 180)
        XCTAssertEqual(profile.weight, 75)
    }

    func testEnumsExist() throws {
        _ = IntensityLevel.easy
        _ = SensorType.heartRate
        _ = GoalType.workouts
        _ = Gender.male
        _ = UnitSystem.metric
    }

    // MARK: - Services

    func testLocationManagerExists() throws {
        let lm = LocationManager()
        XCTAssertFalse(lm.isTrackingLocation)
    }

    func testSensorManagerExists() throws {
        let sm = SensorManager()
        XCTAssertFalse(sm.isConnected)
    }

    func testWorkoutRecorderExists() throws {
        let wr = WorkoutRecorder()
        XCTAssertEqual(wr.state, .idle)
    }

    // MARK: - SwiftData Model Schema

    func testAllModelsRegisteredInSchema() throws {
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
        XCTAssertNotNil(container.mainContext)
    }

    // MARK: - Views (compile check only — types must exist)

    func testHomeViewExists() throws {
        let _ = HomeView()
    }

    func testWorkoutSetupViewExists() throws {
        let _ = WorkoutSetupView()
    }

    func testWorkoutListViewExists() throws {
        let _ = WorkoutListView()
    }

    func testAnalysisViewExists() throws {
        let _ = AnalysisView()
    }

    func testSettingsViewExists() throws {
        let _ = SettingsView()
    }
}
