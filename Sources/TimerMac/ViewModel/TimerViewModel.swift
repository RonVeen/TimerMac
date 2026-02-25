import Foundation
import SwiftUI

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var activities: [Activity] = []
    @Published private(set) var jobs: [Job] = []
    @Published var filter: ActivityDateFilter = .today
    @Published var selectedActivityID: Int64?
    @Published var selectedJobID: Int64?
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var isWorking: Bool = false

    private let activityService: ActivityService
    private let jobService: JobService
    private let configuration: ConfigurationStore

    init(activityService: ActivityService,
         jobService: JobService,
         configuration: ConfigurationStore) {
        self.activityService = activityService
        self.jobService = jobService
        self.configuration = configuration
        Task { await loadInitialData() }
    }

    var selectedActivity: Activity? {
        guard let id = selectedActivityID else { return nil }
        return activities.first { $0.id == id }
    }

    var selectedJob: Job? {
        guard let id = selectedJobID else { return nil }
        return jobs.first { $0.id == id }
    }

    var activeActivity: Activity? {
        activities.first { $0.status == .active }
    }

    func loadInitialData() async {
        refreshActivities()
        refreshJobs()
    }

    func refreshActivities() {
        do {
            activities = try activityService.activities(filter: filter)
            if let selectedActivityID,
               !activities.contains(where: { $0.id == selectedActivityID }) {
                self.selectedActivityID = nil
            }
        } catch {
            handleError(error)
        }
    }

    func refreshJobs() {
        do {
            jobs = try jobService.listJobs().sorted { lhs, rhs in
                lhs.description.localizedCaseInsensitiveCompare(rhs.description) == .orderedAscending
            }
            if let selectedJobID,
               !jobs.contains(where: { $0.id == selectedJobID }) {
                self.selectedJobID = nil
            }
        } catch {
            handleError(error)
        }
    }

    func startActivity(description: String,
                       type: ActivityType,
                       startDate: Date,
                       connectToPrevious: Bool) {
        do {
            var startTime = startDate
            if connectToPrevious {
                if let last = try activityService.latestActivity(on: startDate),
                   let end = last.endTime {
                    startTime = Calendar.current.date(byAdding: .minute, value: 1, to: end) ?? startDate
                } else {
                    errorMessage = "Latest activity has no end time."
                    return
                }
            }
            _ = try activityService.startActivity(type: type,
                                                  description: description,
                                                  startTime: startTime)
            refreshActivities()
        } catch {
            handleError(error)
        }
    }

    func startFromJob(job: Job,
                      type: ActivityType,
                      startDate: Date) {
        startActivity(description: job.description,
                      type: type,
                      startDate: startDate,
                      connectToPrevious: false)
    }

    func stopActivity() {
        do {
            if let stopped = try activityService.stopActiveActivity() {
                infoMessage = "Stopped activity #\(stopped.id)"
            } else {
                infoMessage = "No active activity found."
            }
            refreshActivities()
        } catch {
            handleError(error)
        }
    }

    func restartSelectedActivity() {
        guard let id = selectedActivity?.id else { return }
        do {
            if let newActivity = try activityService.restartActivity(activityID: id) {
                infoMessage = "Restarted as activity #\(newActivity.id)"
                refreshActivities()
            }
        } catch {
            handleError(error)
        }
    }

    func addManualActivity(state: ActivityEditorState) {
        do {
            _ = try activityService.addCompletedActivity(state: state)
            refreshActivities()
        } catch {
            handleError(error)
        }
    }

    func edit(activity: Activity, state: ActivityEditorState) {
        do {
            _ = try activityService.update(activity: activity, state: state)
            refreshActivities()
        } catch {
            handleError(error)
        }
    }

    func copy(activity: Activity, state: ActivityEditorState) {
        do {
            _ = try activityService.copy(activity: activity, state: state)
            refreshActivities()
        } catch {
            handleError(error)
        }
    }

    func deleteSelectedActivity() {
        guard let id = selectedActivity?.id else { return }
        do {
            try activityService.deleteActivity(id: id)
            refreshActivities()
        } catch {
            handleError(error)
        }
    }

    func addJob(description: String) {
        do {
            _ = try jobService.addJob(description: description)
            refreshJobs()
        } catch {
            handleError(error)
        }
    }

    func deleteSelectedJob() {
        guard let id = selectedJob?.id else { return }
        do {
        try jobService.deleteJob(id: id)
        refreshJobs()
        } catch {
            handleError(error)
        }
    }

    func exportData() -> Data? {
        do {
            let activities = try activityService.activities(filter: filter)
            return CsvExporter.makeCSVData(activities: activities,
                                           delimiter: configuration.csvDelimiter)
        } catch {
            handleError(error)
            return nil
        }
    }

    func handleExportCompletion(url: URL) {
        infoMessage = "Exported to \(url.path)"
    }

    func graphSummaries(filter: ActivityDateFilter, referenceDate: Date = Date()) -> [ActivityGraphSummary] {
        let calendar = Calendar.current
        let baseDate = baseDate(for: filter, referenceDate: referenceDate)
        let periods: [(String, DateInterval?)] = [
            ("Today", calendar.dateInterval(of: .day, for: baseDate)),
            ("This Week", calendar.dateInterval(of: .weekOfYear, for: baseDate)),
            ("This Month", calendar.dateInterval(of: .month, for: baseDate))
        ]

        var summaries: [ActivityGraphSummary] = periods.compactMap { title, interval in
            guard let interval else { return nil }
            do {
                let totals = try activityService.durations(from: interval.start, to: interval.end, reference: baseDate)
                let segments = totals
                    .sorted { $0.key.displayName < $1.key.displayName }
                    .map { ActivityGraphSegment(type: $0.key, minutes: Int($0.value / 60)) }
                return ActivityGraphSummary(title: title, segments: segments)
            } catch {
                handleError(error)
                return nil
            }
        }
        let needsFallback: Bool
        switch filter {
        case .today, .yesterday, .specific:
            needsFallback = true
        default:
            needsFallback = false
        }
        if needsFallback {
            if let index = summaries.firstIndex(where: { $0.title == "Today" }),
               summaries[index].totalMinutes == 0 {
                let segments = segmentsFromDisplayedActivities(referenceDate: referenceDate)
                if !segments.isEmpty {
                    summaries[index] = ActivityGraphSummary(title: "Today", segments: segments)
                }
            }
        }
        return summaries
    }

    func defaultActivityState() -> ActivityEditorState {
        ActivityEditorState.default(configuration: configuration)
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    private func baseDate(for filter: ActivityDateFilter, referenceDate: Date) -> Date {
        let calendar = Calendar.current
        switch filter {
        case .today:
            return referenceDate
        case .yesterday:
            return calendar.date(byAdding: .day, value: -1, to: referenceDate) ?? referenceDate
        case .specific(let date):
            return date
        case .from(let date):
            return date
        case .range(let start, _):
            return start
        case .all:
            return referenceDate
        }
    }

    private func segmentsFromDisplayedActivities(referenceDate: Date) -> [ActivityGraphSegment] {
        let totals = activities.reduce(into: [ActivityType: TimeInterval]()) { partial, activity in
            let end = activity.endTime ?? (activity.status == .active ? referenceDate : activity.startTime)
            guard end > activity.startTime else { return }
            partial[activity.activityType, default: 0] += end.timeIntervalSince(activity.startTime)
        }
        return totals
            .sorted { $0.key.displayName < $1.key.displayName }
            .map { ActivityGraphSegment(type: $0.key, minutes: Int($0.value / 60)) }
    }
}

struct ActivityGraphSegment: Identifiable {
    let id = UUID()
    let type: ActivityType
    let minutes: Int

    var color: Color { type.color }
}

struct ActivityGraphSummary: Identifiable {
    let id = UUID()
    let title: String
    let segments: [ActivityGraphSegment]

    var totalMinutes: Int {
        segments.reduce(0) { $0 + $1.minutes }
    }
}
