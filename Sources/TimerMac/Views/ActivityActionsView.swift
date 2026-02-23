import SwiftUI

struct ActivityActionsView: View {
    @ObservedObject var viewModel: TimerViewModel
    let onStart: () -> Void
    let onManual: () -> Void
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        HStack {
            Button("Start Activity", action: onStart)
            Button("Stop Active") {
                viewModel.stopActivity()
            }
            .disabled(viewModel.activeActivity == nil)

            Button("Add Completed", action: onManual)
            Button("Edit", action: onEdit)
                .disabled(viewModel.selectedActivity == nil)

            Button("Copy", action: onCopy)
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

            Button("Export CSV", action: onExport)
                .disabled(viewModel.activities.isEmpty)
        }
    }
}
