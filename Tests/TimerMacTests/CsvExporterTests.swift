import XCTest
@testable import TimerMac

final class CsvExporterTests: XCTestCase {
    func testMakeCSVDataFormatsActivities() throws {
        let start = Date(timeIntervalSince1970: 0)
        let activities = [
            Activity(id: 1,
                     startTime: start,
                     endTime: start.addingTimeInterval(3600),
                     activityType: .develop,
                     status: .completed,
                     description: "Implement feature"),
            Activity(id: 2,
                     startTime: start.addingTimeInterval(7200),
                     endTime: nil,
                     activityType: .meeting,
                     status: .active,
                     description: "Weekly sync, \"planning\"")
        ]

        let data = CsvExporter.makeCSVData(activities: activities, delimiter: ",")
        XCTAssertNotNil(data)

        let csv = String(data: data!, encoding: .utf8)!
        let rows = csv.split(separator: "\n")
        XCTAssertEqual(rows.first, "id,start_time,end_time,activity_type,status,description")
        XCTAssertTrue(csv.contains("Implement feature"))
        XCTAssertTrue(csv.contains("\"Weekly sync, \"\"planning\"\"\""), "Description should be escaped")
    }
}
