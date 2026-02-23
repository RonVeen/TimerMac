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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            filterHeader
            ActivityListView(activities: viewModel.activities,
                             selection: $viewModel.selectedActivityID)
                .frame(minHeight: 280)

            activityActions
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
                      defaultFilename: exportFilename) { _ in }
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
        .onAppear {
            editorState = viewModel.defaultActivityState()
            applyFilterChoice()
        }
    }

    private var filterHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Filter", selection: $filterChoice) {
                    ForEach(FilterChoice.allCases, id: \.self) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .pickerStyle(.segmented)
                Spacer()
                if let active = viewModel.activeActivity {
                    Text("Active: #\(active.id) • \(active.description)")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                } else {
                    Text("No active activity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                switch filterChoice {
                case .today, .yesterday, .all:
                    EmptyView()
                case .date:
                    DatePicker("Date", selection: $specificDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .frame(maxWidth: 250)
                case .from:
                    DatePicker("From", selection: $fromDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .frame(maxWidth: 250)
                case .range:
                    DatePicker("Start", selection: $rangeStart, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    DatePicker("End", selection: $rangeEnd, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                Spacer()
                Button("Refresh") { viewModel.refreshActivities() }
            }
        }
        .onChange(of: filterChoice) { _ in applyFilterChoice() }
        .onChange(of: specificDate) { _ in if filterChoice == .date { applyFilterChoice() } }
        .onChange(of: fromDate) { _ in if filterChoice == .from { applyFilterChoice() } }
        .onChange(of: rangeStart) { _ in if filterChoice == .range { applyFilterChoice() } }
        .onChange(of: rangeEnd) { _ in if filterChoice == .range { applyFilterChoice() } }
    }

    private var activityActions: some View {
        HStack {
            Button("Start Activity") {
                activeSheet = .start(description: "")
            }
            Button("Stop Active") {
                viewModel.stopActivity()
            }
            .disabled(viewModel.activeActivity == nil)

            Button("Add Completed") {
                activeSheet = .manual
            }
            Button("Edit") {
                if let activity = viewModel.selectedActivity {
                    activeSheet = .edit(activity)
                }
            }
            .disabled(viewModel.selectedActivity == nil)

            Button("Copy") {
                if let activity = viewModel.selectedActivity {
                    activeSheet = .copy(activity)
                }
            }
            .disabled(viewModel.selectedActivity == nil)

            Button("Restart") {
                viewModel.restartSelectedActivity()
            }
            .disabled(viewModel.selectedActivity == nil)

            Button("Delete") {
                viewModel.deleteSelectedActivity()
            }
            .disabled(viewModel.selectedActivity == nil)

            Spacer()

            Button("Export CSV") {
                if let data = viewModel.exportData() {
                    exportDocument = CSVDocument(data: data)
                    isExporting = true
                }
            }
            .disabled(viewModel.activities.isEmpty)
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

private enum FilterChoice: CaseIterable {
    case today
    case yesterday
    case date
    case from
    case range
    case all

    var title: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .date: return "Specific"
        case .from: return "From"
        case .range: return "Range"
        case .all: return "All"
        }
    }
}

private enum ActivitySheet: Identifiable, Equatable {
    case start(description: String)
    case manual
    case edit(Activity)
    case copy(Activity)

    var id: String {
        switch self {
        case .start: return "start"
        case .manual: return "manual"
        case .edit(let activity): return "edit_\(activity.id)"
        case .copy(let activity): return "copy_\(activity.id)"
        }
    }

    static func == (lhs: ActivitySheet, rhs: ActivitySheet) -> Bool {
        lhs.id == rhs.id
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
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            ActivityEditorView(state: $state, allowStatusChange: allowStatusChange)
                .frame(width: 420)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button(primaryButtonLabel) {
                    state.description = state.description.trimmed()
                    guard !state.description.isBlank else { return }
                    onSave(state)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.description.isBlank)
            }
        }
        .padding()
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
