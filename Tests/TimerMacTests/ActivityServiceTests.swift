import XCTest
@testable import TimerMac

final class ActivityServiceTests: XCTestCase {
    private func makeService(rounding: Int = 5, duration: Int = 60) -> (ActivityService, InMemoryActivityRepository) {
        let repository = InMemoryActivityRepository()
        let configuration = ConfigurationStore.testInstance(rounding: rounding, duration: duration)
        let service = ActivityService(repository: repository, configuration: configuration)
        return (service, repository)
    }

    func testStartingActivityCompletesExistingActiveAndTrimsDescription() throws {
        let (service, repository) = makeService()
        let start = Date()
        let first = try service.startActivity(type: .develop, description: " First Task ", startTime: start)
        XCTAssertEqual(first.description, "First Task")
        XCTAssertEqual(first.status, .active)

        _ = try service.startActivity(type: .bug, description: "Second", startTime: start.addingTimeInterval(60))

        let active = try repository.findByStatus(.active)
        let completed = try repository.findByStatus(.completed)
        XCTAssertEqual(active.count, 1, "Only one activity should remain active")
        XCTAssertEqual(completed.count, 1, "Previous activity should be completed")
        XCTAssertEqual(completed.first?.id, first.id)
    }

    func testStopActivityAppliesRounding() throws {
        let roundingMinutes = 15
        let (service, _) = makeService(rounding: roundingMinutes)
        let start = Date(timeIntervalSince1970: 0)
        _ = try service.startActivity(type: .develop, description: "Work", startTime: start)

        let reference = start.addingTimeInterval(7 * 60) // 7 minutes after start
        let stopped = try service.stopActiveActivity(reference: reference)

        XCTAssertNotNil(stopped)
        XCTAssertEqual(stopped?.status, .completed)
        XCTAssertEqual(stopped?.endTime, start.addingTimeInterval(TimeInterval(roundingMinutes * 60)), "End time should round up to next interval")
    }

    func testAddCompletedActivityWithoutEndUsesDefaultDuration() throws {
        let defaultDuration = 90
        let (service, _) = makeService(duration: defaultDuration)
        let start = Date()
        var state = ActivityEditorState(description: "Manual entry",
                                        type: .develop,
                                        startDate: start,
                                        endDate: start,
                                        includeEnd: false,
                                        status: .completed)

        let activity = try service.addCompletedActivity(state: state)

        XCTAssertEqual(activity.endTime, start.addingTimeInterval(TimeInterval(defaultDuration * 60)))
        XCTAssertEqual(activity.status, .completed)

        state.description = "  Trim Me  "
        let trimmedActivity = try service.addCompletedActivity(state: state)
        XCTAssertEqual(trimmedActivity.description, "Trim Me")
    }
}
