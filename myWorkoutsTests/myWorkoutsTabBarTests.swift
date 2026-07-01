import XCTest
@testable import myWorkouts

final class myWorkoutsTabBarTests: XCTestCase {

    func testContentViewHasFiveTabs() throws {
        let contentView = ContentView()
        let tabCount = contentView.tabCount
        XCTAssertEqual(tabCount, 5, "ContentView must define exactly 5 tabs")
    }

    func testTabIdentifiersMatchExpected() throws {
        let expectedTabs = ["home", "record", "history", "analysis", "settings"]
        let contentView = ContentView()
        XCTAssertEqual(contentView.tabIdentifiers, expectedTabs, "Tab identifiers must match: home, record, history, analysis, settings")
    }
}
