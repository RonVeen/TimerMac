import XCTest
@testable import TimerMac

final class TimerMacTests: XCTestCase {
    func testConfigurationStoreUsesCustomDefaults() {
        let suiteName = "TimerMacTests.Configuration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("SUPPORT", forKey: "default.activity.type")
        defaults.set(",", forKey: "csv.delimiter")
        defaults.set(45, forKey: "default.duration.minutes")

        let store = ConfigurationStore(userDefaults: defaults)
        XCTAssertEqual(store.defaultActivityType, .support)
        XCTAssertEqual(store.csvDelimiter, ",")
        XCTAssertEqual(store.defaultDurationMinutes, 45)
    }
}
