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
            jobs = try jobService.listJobs()
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

    func defaultActivityState() -> ActivityEditorState {
        ActivityEditorState.default(configuration: configuration)
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}
