import SwiftUI

struct FilterHeaderView: View {
    @Binding var filterChoice: FilterChoice
    @Binding var specificDate: Date
    @Binding var fromDate: Date
    @Binding var rangeStart: Date
    @Binding var rangeEnd: Date
    
    var activeActivity: Activity?
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Filter", selection: $filterChoice) {
                    ForEach(FilterChoice.allCases, id: \.self) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .pickerStyle(.segmented)
                Spacer()
                if let active = activeActivity {
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
                Button("Refresh", action: onRefresh)
            }
        }
    }
}
