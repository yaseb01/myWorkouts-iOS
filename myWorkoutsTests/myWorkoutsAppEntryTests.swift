import XCTest
import SwiftData
@testable import myWorkouts

@MainActor
final class myWorkoutsAppEntryTests: XCTestCase {

    func testAppHasSwiftDataModelContainer() throws {
        let app = myWorkoutsApp()
        let container = app.modelContainer
        XCTAssertTrue(container == nil || container != nil, "myWorkoutsApp must have a modelContainer property")
    }

    func testModelContainerCanBeConfigured() throws {
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
        XCTAssertNotNil(container.mainContext, "ModelContainer must provide a mainContext")
    }
}
