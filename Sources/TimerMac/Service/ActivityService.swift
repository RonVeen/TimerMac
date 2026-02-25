import Foundation

final class ActivityService {
    private let repository: ActivityRepository
    private let configuration: ConfigurationStore

    init(repository: ActivityRepository = SQLiteActivityRepository(),
         configuration: ConfigurationStore) {
        self.repository = repository
        self.configuration = configuration
    }

    func startActivity(type: ActivityType, description: String, startTime: Date) throws -> Activity {
        try repository.updateStatus(current: .active, newStatus: .completed, endTime: startTime)
        var activity = Activity(id: 0,
                                startTime: startTime,
                                endTime: nil,
                                activityType: type,
                                status: .active,
                                description: description.trimmed())
        activity = try repository.save(activity: activity)
        return activity
    }

    func stopActiveActivity(reference: Date = Date()) throws -> Activity? {
        guard var activity = try repository.findByStatus(.active).first else { return nil }
        let rounding = configuration.roundingMinutes
        let endTime = rounding > 1 ? reference.roundedUp(toMinutes: rounding) : reference
        activity.endTime = endTime
        activity.status = .completed
        return try repository.update(activity: activity)
    }

    func restartActivity(activityID: Int64) throws -> Activity? {
        guard let source = try repository.findById(activityID) else { return nil }
        _ = try stopActiveActivity()
        return try startActivity(type: source.activityType,
                                 description: source.description,
                                 startTime: Date())
    }

    func addCompletedActivity(state: ActivityEditorState) throws -> Activity {
        var endTime = state.endDate
        if !state.includeEnd {
            endTime = Calendar.current.date(byAdding: .minute,
                                            value: configuration.defaultDurationMinutes,
                                            to: state.startDate) ?? state.startDate
        }
        var activity = Activity(id: 0,
                                startTime: state.startDate,
                                endTime: endTime,
                                activityType: state.type,
                                status: .completed,
                                description: state.description.trimmed())
        activity = try repository.save(activity: activity)
        return activity
    }

    func update(activity: Activity, state: ActivityEditorState) throws -> Activity {
        var updated = activity
        updated.startTime = state.startDate
        updated.endTime = state.includeEnd ? state.endDate : nil
        updated.activityType = state.type
        updated.description = state.description.trimmed()
        updated.status = state.status
        return try repository.update(activity: updated)
    }

    func copy(activity: Activity, state: ActivityEditorState) throws -> Activity {
        var newActivity = Activity(id: 0,
                                   startTime: state.startDate,
                                   endTime: state.endDate,
                                   activityType: state.type,
                                   status: .completed,
                                   description: state.description.trimmed())
        newActivity = try repository.save(activity: newActivity)
        return newActivity
    }

    func deleteActivity(id: Int64) throws {
        try repository.delete(id: id)
    }

    func activities(filter: ActivityDateFilter) throws -> [Activity] {
        switch filter {
        case .all:
            return try repository.findAll()
        case .today:
            let (from, to) = filter.bounds()
            return try fetchRange(from: from!, to: to!)
        case .yesterday:
            let (from, to) = filter.bounds()
            return try fetchRange(from: from!, to: to!)
        case .specific(let date):
            return try repository.findByDate(date)
        case .from(let date):
            let (from, to) = filter.bounds()
            return try fetchRange(from: from ?? date, to: to ?? Date())
        case .range(let start, let end):
            return try fetchRange(from: start, to: end)
        }
    }

    func latestActivity(on date: Date) throws -> Activity? {
        try repository.findLatestActivity(on: date)
    }

    func activeActivities() throws -> [Activity] {
        try repository.findByStatus(.active)
    }

    func durations(from start: Date, to end: Date, reference: Date = Date()) throws -> [ActivityType: TimeInterval] {
        let activities = try repository.findByDateRange(from: start, to: end)
        var totals: [ActivityType: TimeInterval] = [:]
        for activity in activities {
            let endTime = activity.endTime ?? (activity.status == .active ? reference : activity.startTime)
            guard endTime > activity.startTime else { continue }
            let duration = endTime.timeIntervalSince(activity.startTime)
            totals[activity.activityType, default: 0] += duration
        }
        return totals
    }

    private func fetchRange(from: Date, to: Date) throws -> [Activity] {
        let lower = min(from, to)
        let upper = max(from, to)
        return try repository.findByDateRange(from: lower, to: upper)
    }
}

final class JobService {
    private let repository: JobRepository

    init(repository: JobRepository = SQLiteJobRepository()) {
        self.repository = repository
    }

    func addJob(description: String) throws -> Job {
        var job = Job(id: 0, description: description.trimmed())
        job = try repository.save(job: job)
        return job
    }

    func deleteJob(id: Int64) throws {
        try repository.delete(id: id)
    }

    func listJobs() throws -> [Job] {
        try repository.findAll()
    }

    func job(id: Int64) throws -> Job? {
        try repository.findById(id)
    }
}
