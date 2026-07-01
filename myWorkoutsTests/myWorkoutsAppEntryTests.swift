import XCTest
@testable import myWorkouts

@MainActor
final class myWorkoutsAppEntryTests: XCTestCase {

    func testAppHasSwiftDataModelContainer() throws {
        let app = myWorkoutsApp()
        XCTAssertNotNil(app.modelContainer, "myWorkoutsApp must provide a ModelContainer")
    }

    func testModelContainerIsConfigured() throws {
        let app = myWorkoutsApp()
        let container = app.modelContainer
        XCTAssertNotNil(container.mainContext, "ModelContainer must provide a mainContext")
    }
}
