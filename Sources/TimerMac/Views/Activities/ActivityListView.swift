import AppKit
import SwiftUI

struct ActivityListView: View {
    let activities: [Activity]
    @Binding var selection: Int64?
    var onDoubleClick: ((Activity) -> Void)?

    @State private var tableSelection = Set<Int64>()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if activities.isEmpty {
                emptyState
            } else {
                Table(activities, selection: $tableSelection) {
                    TableColumn("ID") { activity in
                        Text(activity.id == 0 ? "-" : "\(activity.id)")
                            .fontWeight(activity.isRunning ? .bold : .regular)
                    }
                    .width(min: 30, ideal: 40, max: 50)

                    TableColumn("Description") { activity in
                        Text(activity.description)
                    }
                    .width(min: 150, ideal: 300)

                    TableColumn("Date") { activity in
                        Text(DateFormatters.date().string(from: activity.startTime))
                    }
                    .width(min: 80, ideal: 100, max: 120)

                    TableColumn("Start") { activity in
                        Text(DateFormatters.time().string(from: activity.startTime))
                    }
                    .width(min: 45, ideal: 55, max: 65)

                    TableColumn("End") { activity in
                        if let end = activity.endTime {
                            Text(DateFormatters.time().string(from: end))
                        } else {
                            Text(activity.isRunning ? "Running" : "-")
                                .foregroundStyle(activity.isRunning ? .green : .secondary)
                        }
                    }
                    .width(min: 45, ideal: 55, max: 65)

                    TableColumn("Duration") { activity in
                        Text(activity.durationText)
                    }
                    .width(min: 50, ideal: 65, max: 80)

                    TableColumn("Type") { activity in
                        Text(activity.activityType.displayName)
                    }
                    .width(min: 60, ideal: 80, max: 100)

                    TableColumn("Status") { activity in
                        Text(activity.status.displayName)
                    }
                    .width(min: 60, ideal: 80, max: 100)
                }
                .tableDoubleClickHandler {
                    guard let selectedID = tableSelection.first,
                          let activity = activities.first(where: { $0.id == selectedID }),
                          !activity.isRunning else { return }
                    onDoubleClick?(activity)
                }

                Text("Total duration: \(ActivityDurationFormatter.totalText(for: activities))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: tableSelection) { newSelection in
            selection = newSelection.first
        }
        .onChange(of: selection) { newValue in
            if let value = newValue {
                tableSelection = [value]
            } else {
                tableSelection.removeAll()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No activities found")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Start a new activity or change the filter to see results.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - NSTableView double-click wiring

private struct TableDoubleClickFinder: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let tableView = findTableView(in: view) else { return }
            context.coordinator.tableView = tableView
            tableView.target = context.coordinator
            tableView.doubleAction = #selector(Coordinator.onDoubleClick)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    private func findTableView(in view: NSView) -> NSTableView? {
        // Walk up from our injected view to find the NSTableView
        var current: NSView? = view
        while let v = current {
            if let found = findTableViewDown(in: v) {
                return found
            }
            current = v.superview
        }
        return nil
    }

    private func findTableViewDown(in view: NSView) -> NSTableView? {
        if let tableView = view as? NSTableView {
            return tableView
        }
        for subview in view.subviews {
            if let found = findTableViewDown(in: subview) {
                return found
            }
        }
        return nil
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        weak var tableView: NSTableView?

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @MainActor @objc func onDoubleClick() {
            guard let tableView, tableView.clickedRow >= 0 else { return }
            action()
        }
    }
}

extension View {
    func tableDoubleClickHandler(perform action: @escaping () -> Void) -> some View {
        background { TableDoubleClickFinder(action: action) }
    }
}
