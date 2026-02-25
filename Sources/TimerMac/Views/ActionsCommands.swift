import SwiftUI

struct ActivityActions {
    var startActivity: () -> Void
    var stopActivity: () -> Void
    var addCompleted: () -> Void
    var editActivity: () -> Void
    var copyActivity: () -> Void
    var restartActivity: () -> Void
    var deleteActivity: () -> Void
    var exportCSV: () -> Void
    var showGraph: () -> Void

    var hasActiveActivity: Bool
    var hasSelectedActivity: Bool
    var hasActivities: Bool
}

private struct ActivityActionsKey: FocusedValueKey {
    typealias Value = ActivityActions
}

extension FocusedValues {
    var activityActions: ActivityActions? {
        get { self[ActivityActionsKey.self] }
        set { self[ActivityActionsKey.self] = newValue }
    }
}

struct ActionsCommands: Commands {
    @FocusedValue(\.activityActions) private var actions

    var body: some Commands {
        CommandMenu("Actions") {
            Button("Start Activity") {
                actions?.startActivity()
            }
            .keyboardShortcut("n")

            Button("Stop Active") {
                actions?.stopActivity()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(actions?.hasActiveActivity != true)

            Divider()

            Button("Add Completed") {
                actions?.addCompleted()
            }

            Button("Edit") {
                actions?.editActivity()
            }
            .keyboardShortcut("e")
            .disabled(actions?.hasSelectedActivity != true)

            Button("Copy") {
                actions?.copyActivity()
            }
            .keyboardShortcut("d")
            .disabled(actions?.hasSelectedActivity != true)

            Button("Restart") {
                actions?.restartActivity()
            }
            .keyboardShortcut("r")
            .disabled(actions?.hasSelectedActivity != true)

            Divider()

            Button("Delete") {
                actions?.deleteActivity()
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(actions?.hasSelectedActivity != true)

            Divider()

            Button("Export CSV") {
                actions?.exportCSV()
            }
            .disabled(actions?.hasActivities != true)

            Button("Show Graph") {
                actions?.showGraph()
            }
            .disabled(actions?.hasActivities != true)
        }
    }
}
