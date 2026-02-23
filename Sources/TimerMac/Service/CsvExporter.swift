import Foundation

struct CsvExporter {
    static func makeCSVData(activities: [Activity], delimiter: String) -> Data? {
        var rows: [String] = []
        let header = ["id", "start_time", "end_time", "activity_type", "status", "description"]
            .joined(separator: delimiter)
        rows.append(header)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for activity in activities {
            let start = formatter.string(from: activity.startTime)
            let end = activity.endTime.map { formatter.string(from: $0) } ?? ""
            let columns = [
                String(activity.id),
                start,
                end,
                activity.activityType.rawValue,
                activity.status.rawValue,
                escape(activity.description, delimiter: delimiter)
            ]
            rows.append(columns.joined(separator: delimiter))
        }

        let csvString = rows.joined(separator: "\n")
        return csvString.data(using: .utf8)
    }

    static func write(activities: [Activity], delimiter: String, url: URL) throws {
        guard let data = makeCSVData(activities: activities, delimiter: delimiter) else { return }
        try data.write(to: url, options: .atomic)
    }

    private static func escape(_ value: String, delimiter: String) -> String {
        if value.contains(delimiter) || value.contains("\n") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
