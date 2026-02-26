import SwiftUI

struct ActivityActionsView: View {
    @ObservedObject var viewModel: TimerViewModel
    let onStart: () -> Void
    let onManual: () -> Void
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onExport: () -> Void
    let onGraph: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Primary actions
            Button("Start Activity", action: onStart)
                .buttonStyle(.borderedProminent)

            Button("Stop Active") {
                viewModel.stopActivity()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(viewModel.activeActivity == nil)

            Divider().frame(height: 20)

            // Secondary actions
            Button("Add Completed", action: onManual)

            Divider().frame(height: 20)

            Button("Edit", action: onEdit)
                .disabled(viewModel.selectedActivity == nil)

            Button("Copy", action: onCopy)
                .disabled(viewModel.selectedActivity == nil)

            Button("Restart") {
                viewModel.restartSelectedActivity()
            }
            .disabled(viewModel.selectedActivity == nil)

            Divider().frame(height: 20)

            // Destructive
            Button("Delete") {
                showDeleteConfirmation = true
            }
            .foregroundStyle(.red)
            .disabled(viewModel.selectedActivity == nil)

            Spacer()

            Button {
                onGraph()
            } label: {
                Image(systemName: "chart.pie.fill")
                    .font(.title3)
            }
            .help("Show activity breakdown")

            Button("Export CSV", action: onExport)
                .disabled(viewModel.activities.isEmpty)
        }
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
}
