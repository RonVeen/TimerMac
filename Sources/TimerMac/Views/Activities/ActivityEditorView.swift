import SwiftUI

struct ActivityEditorView: View {
    @Binding var state: ActivityEditorState
    var allowStatusChange: Bool = false

    var body: some View {
        Form {
            TextField("Description", text: $state.description)
            Picker("Type", selection: $state.type) {
                ForEach(ActivityType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            DatePicker("Start", selection: $state.startDate, displayedComponents: [.date, .hourAndMinute])
            Toggle("Specify end time", isOn: $state.includeEnd)
            if state.includeEnd {
                DatePicker("End", selection: $state.endDate, displayedComponents: [.date, .hourAndMinute])
            }
            if allowStatusChange {
                Picker("Status", selection: $state.status) {
                    ForEach(ActivityStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
            }
        }
        .onChange(of: state.startDate) { newValue in
            if state.endDate < newValue {
                state.endDate = newValue
            }
        }
    }
}

struct StartActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var description: String
    @State private var type: ActivityType
    @State private var startDate: Date
    @State private var connectToPrevious: Bool
    let onSubmit: (String, ActivityType, Date, Bool) -> Void
    private var isDescriptionValid: Bool {
        !description.isBlank
    }

    init(description: String,
         type: ActivityType,
         startDate: Date,
         connectToPrevious: Bool = false,
         onSubmit: @escaping (String, ActivityType, Date, Bool) -> Void) {
        _description = State(initialValue: description)
        _type = State(initialValue: type)
        _startDate = State(initialValue: startDate)
        _connectToPrevious = State(initialValue: connectToPrevious)
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Start Activity")
                .font(.headline)

            Form {
                TextField("Description", text: $description)
                Picker("Type", selection: $type) {
                    ForEach(ActivityType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                Toggle("Connect to last activity today", isOn: $connectToPrevious)
                    .help("Uses the previous activity's end time + 1 minute")
            }
            .frame(width: 420)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Start") {
                    let trimmed = description.trimmed()
                    guard !trimmed.isEmpty else { return }
                    onSubmit(trimmed, type, startDate, connectToPrevious)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isDescriptionValid)
            }
        }
        .padding()
    }
}
