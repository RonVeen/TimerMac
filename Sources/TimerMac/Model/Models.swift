import Foundation

enum ActivityType: String, CaseIterable, Identifiable, Codable {
    case bug = "BUG"
    case develop = "DEVELOP"
    case general = "GENERAL"
    case infra = "INFRA"
    case meeting = "MEETING"
    case outOfOffice = "OUT_OF_OFFICE"
    case problem = "PROBLEM"
    case support = "SUPPORT"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bug: return "Bug"
        case .develop: return "Develop"
        case .general: return "General"
        case .infra: return "Infra"
        case .meeting: return "Meeting"
        case .outOfOffice: return "Out of Office"
        case .problem: return "Problem"
        case .support: return "Support"
        }
    }
}

enum ActivityStatus: String, CaseIterable, Identifiable, Codable {
    case active = "ACTIVE"
    case paused = "PAUSED"
    case completed = "COMPLETED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }
}

struct Activity: Identifiable, Equatable {
    var id: Int64
    var startTime: Date
    var endTime: Date?
    var activityType: ActivityType
    var status: ActivityStatus
    var description: String

    var isRunning: Bool { status == .active }

    var durationText: String {
        guard let end = endTime ?? (isRunning ? Date() : nil) else { return "-" }
        let duration = Int(end.timeIntervalSince(startTime))
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct Job: Identifiable, Equatable {
    var id: Int64
    var description: String
}

enum ActivityDateFilter: Hashable {
    case today
    case yesterday
    case specific(Date)
    case from(Date)
    case range(Date, Date)
    case all

    func bounds(calendar: Calendar = .current) -> (Date?, Date?) {
        switch self {
        case .today:
            let now = Date()
            return (now.startOfDay(in: calendar), now.endOfDay(in: calendar))
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            return (yesterday.startOfDay(in: calendar), yesterday.endOfDay(in: calendar))
        case .specific(let date):
            return (date.startOfDay(in: calendar), date.endOfDay(in: calendar))
        case .from(let date):
            return (date.startOfDay(in: calendar), Date())
        case .range(let start, let end):
            let lower = min(start, end)
            let upper = max(start, end)
            return (lower.startOfDay(in: calendar), upper.endOfDay(in: calendar))
        case .all:
            return (nil, nil)
        }
    }

    var title: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .specific(let date): return "On \(DateFormatters.date().string(from: date))"
        case .from(let date): return "From \(DateFormatters.date().string(from: date))"
        case .range(let start, let end):
            return "\(DateFormatters.date().string(from: start)) - \(DateFormatters.date().string(from: end))"
        case .all: return "All"
        }
    }
}

struct ActivityEditorState {
    var description: String
    var type: ActivityType
    var startDate: Date
    var endDate: Date
    var includeEnd: Bool
    var status: ActivityStatus

    static func `default`(configuration: ConfigurationStore) -> ActivityEditorState {
        let start = configuration.defaultStartDate(for: Date())
        let defaultEnd = Calendar.current.date(byAdding: .minute,
                                               value: configuration.defaultDurationMinutes,
                                               to: start) ?? start
        return ActivityEditorState(description: "",
                                   type: configuration.defaultActivityType,
                                   startDate: start,
                                   endDate: defaultEnd,
                                   includeEnd: true,
                                   status: .completed)
    }

    static func from(activity: Activity) -> ActivityEditorState {
        ActivityEditorState(description: activity.description,
                            type: activity.activityType,
                            startDate: activity.startTime,
                            endDate: activity.endTime ?? activity.startTime,
                            includeEnd: true,
                            status: activity.status)
    }
}
