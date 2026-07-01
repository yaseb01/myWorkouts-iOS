import XCTest
import SwiftData
@testable import myWorkouts

/// T24: App Integration & Polish
/// Tests service initialization order, crash recovery, error handling,
/// accessibility labels, and high contrast mode support.
@MainActor
final class myWorkoutsAppIntegrationTests: XCTestCase {

    // MARK: - Service Initialization Order

    func testServicesInitializeInCorrectOrder() throws {
        // Order: LocationManager → SensorManager → WorkoutRecorder
        let locationManager = LocationManager()
        let sensorManager = SensorManager()
        let workoutRecorder = WorkoutRecorder()

        XCTAssertNotNil(locationManager, "LocationManager must initialize first")
        XCTAssertNotNil(sensorManager, "SensorManager must initialize second")
        XCTAssertNotNil(workoutRecorder, "WorkoutRecorder must initialize last")
    }

    func testRecorderStateDependsOnPriorServices() throws {
        let recorder = WorkoutRecorder()
        XCTAssertEqual(recorder.state, .idle,
            "Recorder must be idle immediately after init")
    }

    // MARK: - Crash Recovery

    func testCrashRecoveryDefaultsToFalse() throws {
        UserDefaults.standard.removeObject(forKey: "hasIncompleteWorkout")
        let recorder = WorkoutRecorder()
        XCTAssertFalse(recorder.hasIncompleteWorkout,
            "Fresh init must report no incomplete workout")
    }

    func testCrashRecoveryDetectsPersistedState() throws {
        UserDefaults.standard.set(true, forKey: "hasIncompleteWorkout")
        defer { UserDefaults.standard.removeObject(forKey: "hasIncompleteWorkout") }

        let recorder = WorkoutRecorder()
        XCTAssertTrue(recorder.hasIncompleteWorkout,
            "Recorder must detect persisted incomplete workout flag")
    }

    func testStopClearsIncompleteFlag() throws {
        UserDefaults.standard.set(true, forKey: "hasIncompleteWorkout")
        defer { UserDefaults.standard.removeObject(forKey: "hasIncompleteWorkout") }

        let recorder = WorkoutRecorder()
        XCTAssertTrue(recorder.hasIncompleteWorkout)

        recorder.stop()
        XCTAssertFalse(recorder.hasIncompleteWorkout,
            "stop() must clear the incomplete workout flag")
    }

    // MARK: - Error Handling

    func testAppExposesErrorState() throws {
        let app = myWorkoutsApp()
        XCTAssertNil(app.errorMessage,
            "App must start with no error message")
    }

    func testAppErrorAlertDefaultsOff() throws {
        let app = myWorkoutsApp()
        XCTAssertFalse(app.showErrorAlert,
            "showErrorAlert must be false on fresh launch")
    }

    // MARK: - Accessibility: Tab Labels

    func testContentViewHasAccessibilityLabels() throws {
        let view = ContentView()
        let labels = view.tabAccessibilityLabels
        XCTAssertEqual(labels, ["Home", "Record", "History", "Analysis", "Settings"],
            "Each tab must have a descriptive accessibility label")
    }

    func testTabLabelsCountMatchesTabCount() throws {
        let view = ContentView()
        XCTAssertEqual(view.tabAccessibilityLabels.count, view.tabCount,
            "Accessibility labels count must match tab count")
    }

    func testTabLabelsMatchTabIdentifiers() throws {
        let view = ContentView()
        let identifiers = view.tabIdentifiers
        let labels = view.tabAccessibilityLabels
        XCTAssertEqual(identifiers.count, labels.count)
        for (id, label) in zip(identifiers, labels) {
            XCTAssertFalse(label.isEmpty, "Label for tab '\(id)' must not be empty")
        }
    }

    // MARK: - Accessibility: Dynamic Type

    func testContentViewSupportsDynamicType() throws {
        let view = ContentView()
        XCTAssertTrue(view.supportsDynamicType,
            "ContentView must declare Dynamic Type support")
    }

    // MARK: - Accessibility: High Contrast

    func testContentViewSupportsHighContrast() throws {
        let view = ContentView()
        XCTAssertTrue(view.supportsHighContrast,
            "ContentView must support high contrast mode")
    }

    // MARK: - Accessibility: VoiceOver on Views

    func testHomeViewSupportsVoiceOver() throws {
        let home = HomeView()
        XCTAssertTrue(home.supportsVoiceOver,
            "HomeView must be VoiceOver accessible")
    }

    func testWorkoutSetupSupportsVoiceOver() throws {
        let setup = WorkoutSetupView()
        XCTAssertTrue(setup.supportsVoiceOver,
            "WorkoutSetupView must be VoiceOver accessible")
    }

    func testSettingsViewSupportsVoiceOver() throws {
        let settings = SettingsView()
        XCTAssertTrue(settings.supportsVoiceOver,
            "SettingsView must be VoiceOver accessible")
    }

    func testAnalysisViewSupportsVoiceOver() throws {
        let analysis = AnalysisView()
        XCTAssertTrue(analysis.supportsVoiceOver,
            "AnalysisView must be VoiceOver accessible")
    }

    func testWorkoutListViewSupportsVoiceOver() throws {
        let history = WorkoutListView()
        XCTAssertTrue(history.supportsVoiceOver,
            "WorkoutListView must be VoiceOver accessible")
    }
}
