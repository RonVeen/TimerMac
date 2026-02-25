import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel
    @EnvironmentObject var configuration: ConfigurationStore

    @State private var activeSheet: ActivitySheet?
    @State private var editorState = ActivityEditorState(description: "",
                                                         type: .develop,
                                                         startDate: Date(),
                                                         endDate: Date(),
                                                         includeEnd: true,
                                                         status: .completed)
    @State private var filterChoice: FilterChoice = .today
    @State private var specificDate = Date()
    @State private var fromDate = Date()
    @State private var rangeStart = Date()
    @State private var rangeEnd = Date()
    @State private var exportDocument = CSVDocument(data: Data())
    @State private var isExporting = false
    @State private var showDeleteConfirmation = false
    @State private var showGraphPopover = false
    @State private var graphSummaries: [ActivityGraphSummary] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FilterHeaderView(filterChoice: $filterChoice,
                             specificDate: $specificDate,
                             fromDate: $fromDate,
                             rangeStart: $rangeStart,
                             rangeEnd: $rangeEnd,
                             activeActivity: viewModel.activeActivity,
                             onRefresh: { viewModel.refreshActivities() })
            ActivityListView(activities: viewModel.activities,
                             selection: $viewModel.selectedActivityID,
                             onDoubleClick: { activity in
                                 activeSheet = .edit(activity)
                             })
                .frame(minHeight: 280)

            ActivityActionsView(viewModel: viewModel,
                                onStart: { activeSheet = .start(description: "") },
                                onManual: { activeSheet = .manual },
                                onEdit: {
                                    if let activity = viewModel.selectedActivity {
                                        activeSheet = .edit(activity)
                                    }
                                },
                                onCopy: {
                                    if let activity = viewModel.selectedActivity {
                                        activeSheet = .copy(activity)
                                    }
                                },
                                onExport: triggerExport,
                                onGraph: triggerGraph)
            if let info = viewModel.infoMessage {
                Text(info)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Divider()

            JobManagementView(viewModel: viewModel) { job in
                activeSheet = .start(description: job.description)
            }
        }
        .padding()
        .sheet(item: $activeSheet, onDismiss: {
            editorState = viewModel.defaultActivityState()
        }) { sheet in
            sheetContent(for: sheet)
        }
        .onChange(of: activeSheet) { newValue in
            guard let sheet = newValue else { return }
            switch sheet {
            case .start:
                break
            case .manual:
                editorState = viewModel.defaultActivityState()
            case .edit(let activity), .copy(let activity):
                editorState = ActivityEditorState.from(activity: activity)
            }
        }
        .fileExporter(isPresented: $isExporting,
                      document: exportDocument,
                      contentType: .commaSeparatedText,
                      defaultFilename: exportFilename) { result in
            if case .success(let url) = result {
                viewModel.handleExportCompletion(url: url)
            }
        }
        .alert("Error", isPresented: Binding(get: {
            viewModel.errorMessage != nil
        }, set: { newValue in
            if !newValue {
                viewModel.errorMessage = nil
            }
        })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .popover(isPresented: $showGraphPopover) {
            ActivityGraphPopover(summaries: graphSummaries)
        }
        .onAppear {
            editorState = viewModel.defaultActivityState()
            applyFilterChoice()
        }
        .onChange(of: filterChoice) { _ in applyFilterChoice() }
        .onChange(of: specificDate) { _ in if filterChoice == .date { applyFilterChoice() } }
        .onChange(of: fromDate) { _ in if filterChoice == .from { applyFilterChoice() } }
        .onChange(of: rangeStart) { _ in if filterChoice == .range { applyFilterChoice() } }
        .onChange(of: rangeEnd) { _ in if filterChoice == .range { applyFilterChoice() } }
        .focusedValue(\.activityActions, ActivityActions(
            startActivity: { activeSheet = .start(description: "") },
            stopActivity: { viewModel.stopActivity() },
            addCompleted: { activeSheet = .manual },
            editActivity: {
                if let activity = viewModel.selectedActivity {
                    activeSheet = .edit(activity)
                }
            },
            copyActivity: {
                if let activity = viewModel.selectedActivity {
                    activeSheet = .copy(activity)
                }
            },
            restartActivity: { viewModel.restartSelectedActivity() },
            deleteActivity: { showDeleteConfirmation = true },
            exportCSV: triggerExport,
            showGraph: triggerGraph,
            hasActiveActivity: viewModel.activeActivity != nil,
            hasSelectedActivity: viewModel.selectedActivity != nil,
            hasActivities: !viewModel.activities.isEmpty
        ))
        .alert("Delete Activity", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedActivity()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let activity = viewModel.selectedActivity {
                Text("Delete activity #\(activity.id) \"\(activity.description)\"?")
            } else {
                Text("Delete selected activity?")
            }
        }
    }

    private func triggerExport() {
        if let data = viewModel.exportData() {
            exportDocument = CSVDocument(data: data)
            isExporting = true
        }
    }

    private func triggerGraph() {
        graphSummaries = viewModel.graphSummaries(filter: viewModel.filter)
        showGraphPopover = true
    }

    @ViewBuilder
    private func sheetContent(for sheet: ActivitySheet) -> some View {
        switch sheet {
        case .start(let description):
            StartActivityView(description: description,
                              type: configuration.defaultActivityType,
                              startDate: configuration.defaultStartDate(for: Date())) { desc, type, startDate, connect in
                viewModel.startActivity(description: desc,
                                        type: type,
                                        startDate: startDate,
                                        connectToPrevious: connect)
            }
        case .manual:
            ActivityEditorSheet(title: "Add Completed Activity",
                                primaryButtonLabel: "Add",
                                state: $editorState,
                                allowStatusChange: false) { state in
                viewModel.addManualActivity(state: state)
            }
        case .edit(let activity):
            ActivityEditorSheet(title: "Edit Activity",
                                primaryButtonLabel: "Save",
                                state: $editorState,
                                allowStatusChange: true) { state in
                viewModel.edit(activity: activity, state: state)
            }
        case .copy(let activity):
            ActivityEditorSheet(title: "Copy Activity",
                                primaryButtonLabel: "Save Copy",
                                state: $editorState,
                                allowStatusChange: false) { state in
                viewModel.copy(activity: activity, state: state)
            }
        }
    }

    private func applyFilterChoice() {
        switch filterChoice {
        case .today:
            viewModel.filter = .today
        case .yesterday:
            viewModel.filter = .yesterday
        case .date:
            viewModel.filter = .specific(specificDate)
        case .from:
            viewModel.filter = .from(fromDate)
        case .range:
            viewModel.filter = .range(rangeStart, rangeEnd)
        case .all:
            viewModel.filter = .all
        }
        viewModel.refreshActivities()
    }

    private var exportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "activities_\(formatter.string(from: Date()))"
    }
}

struct ActivityEditorSheet: View {
    let title: String
    let primaryButtonLabel: String
    @Binding var state: ActivityEditorState
    var allowStatusChange: Bool
    let onSave: (ActivityEditorState) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.headline)
            
            ActivityEditorView(state: $state, allowStatusChange: allowStatusChange)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .clipShape(Capsule())

                Button(primaryButtonLabel) {
                    state.description = state.description.trimmed()
                    guard !state.description.isBlank else { return }
                    onSave(state)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Capsule())
                .disabled(state.description.isBlank)
            }
        }
        .padding()
        .frame(width: 450)
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
