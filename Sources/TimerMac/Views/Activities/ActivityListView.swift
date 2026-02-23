import SwiftUI

struct ActivityListView: View {
    let activities: [Activity]
    @Binding var selection: Int64?

    @State private var tableSelection = Set<Int64>()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Table(activities, selection: $tableSelection) {
                TableColumn("ID") { activity in
                    Text(activity.id == 0 ? "-" : "\(activity.id)")
                        .fontWeight(activity.isRunning ? .bold : .regular)
                }
                .width(min: 20, ideal: 30, max: 40)
                
                TableColumn("Description") { activity in
                    Text(activity.description)
                }
                .width(min: 100, ideal: 200)
                
                TableColumn("Date") { activity in
                    Text(DateFormatters.date().string(from: activity.startTime))
                }
                TableColumn("Start") { activity in
                    Text(DateFormatters.time().string(from: activity.startTime))
                }
                TableColumn("End") { activity in
                    if let end = activity.endTime {
                        Text(DateFormatters.time().string(from: end))
                    } else {
                        Text(activity.isRunning ? "Running" : "-")
                            .foregroundStyle(activity.isRunning ? .green : .secondary)
                    }
                }
                TableColumn("Duration") { activity in
                    Text(activity.durationText)
                }
                TableColumn("Type") { activity in
                    Text(activity.activityType.displayName)
                }
                TableColumn("Status") { activity in
                    Text(activity.status.displayName)
                }
            }
            Text("Total duration: \(ActivityDurationFormatter.totalText(for: activities))")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
}
