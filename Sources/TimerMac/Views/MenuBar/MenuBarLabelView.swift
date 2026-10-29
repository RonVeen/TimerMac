import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        HStack(spacing: 4) {
            Text("⏱")
            if let activity = viewModel.activeActivity {
                Text(activity.description)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 120, alignment: .leading)
            }
        }
    }
}
