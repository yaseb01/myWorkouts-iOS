import XCTest
@testable import myWorkouts

final class myWorkoutsInfoPlistTests: XCTestCase {

    func testInfoPlistContainsLocationWhenInUseDescription() throws {
        let plist = loadInfoPlist()
        XCTAssertNotNil(
            plist["NSLocationWhenInUseUsageDescription"],
            "Info.plist must contain NSLocationWhenInUseUsageDescription"
        )
        let value = plist["NSLocationWhenInUseUsageDescription"] as? String
        XCTAssertFalse(value?.isEmpty ?? true, "NSLocationWhenInUseUsageDescription must not be empty")
    }

    func testInfoPlistContainsLocationAlwaysDescription() throws {
        let plist = loadInfoPlist()
        XCTAssertNotNil(
            plist["NSLocationAlwaysAndWhenInUseUsageDescription"],
            "Info.plist must contain NSLocationAlwaysAndWhenInUseUsageDescription"
        )
    }

    func testInfoPlistContainsBluetoothAlwaysDescription() throws {
        let plist = loadInfoPlist()
        XCTAssertNotNil(
            plist["NSBluetoothAlwaysUsageDescription"],
            "Info.plist must contain NSBluetoothAlwaysUsageDescription"
        )
    }

    func testInfoPlistContainsBluetoothPeripheralDescription() throws {
        let plist = loadInfoPlist()
        XCTAssertNotNil(
            plist["NSBluetoothPeripheralUsageDescription"],
            "Info.plist must contain NSBluetoothPeripheralUsageDescription"
        )
    }

    func testInfoPlistBackgroundModesContainsLocation() throws {
        let plist = loadInfoPlist()
        guard let backgroundModes = plist["UIBackgroundModes"] as? [String] else {
            XCTFail("Info.plist must contain UIBackgroundModes array")
            return
        }
        XCTAssertTrue(backgroundModes.contains("location"), "Background modes must include 'location'")
    }

    func testInfoPlistBackgroundModesContainsBluetooth() throws {
        let plist = loadInfoPlist()
        guard let backgroundModes = plist["UIBackgroundModes"] as? [String] else {
            XCTFail("Info.plist must contain UIBackgroundModes array")
            return
        }
        XCTAssertTrue(backgroundModes.contains("bluetooth-central"), "Background modes must include 'bluetooth-central'")
    }

    // MARK: - Helpers

    private func loadInfoPlist() -> [String: Any] {
        // Try loading from the test bundle's parent (the app bundle)
        if let path = Bundle(for: type(of: self)).path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) as? [String: Any] {
            return plist
        }

        // Fallback: try the main bundle (works when running as app test)
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) as? [String: Any] {
            return plist
        }

        XCTFail("Could not load Info.plist from any bundle")
        return [:]
    }
}
