import XCTest
@testable import TimerMac

final class ActivityDurationFormatterTests: XCTestCase {
    func testTotalTextFormatsMinutesOnly() {
        let start = Date(timeIntervalSince1970: 0)
        let activity = Activity(id: 1,
                                startTime: start,
                                endTime: start.addingTimeInterval(30 * 60),
                                activityType: .develop,
                                status: .completed,
                                description: "")

        let text = ActivityDurationFormatter.totalText(for: [activity])
        XCTAssertEqual(text, "30 min")
    }

    func testTotalTextHandlesHoursAndRunningActivity() {
        let reference = Date(timeIntervalSince1970: 0)
        let first = Activity(id: 1,
                             startTime: reference,
                             endTime: reference.addingTimeInterval(3600),
                             activityType: .develop,
                             status: .completed,
                             description: "")
        let running = Activity(id: 2,
                               startTime: reference.addingTimeInterval(3600),
                               endTime: nil,
                               activityType: .meeting,
                               status: .active,
                               description: "")

        let text = ActivityDurationFormatter.totalText(for: [first, running],
                                                       referenceDate: reference.addingTimeInterval(5400))
        XCTAssertEqual(text, "1h 30m (90 min)")
    }
}
