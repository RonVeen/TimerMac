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
                activeActivityBadge
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

    @ViewBuilder
    private var activeActivityBadge: some View {
        if let active = activeActivity {
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("#\(active.id) \(active.description)")
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.green.opacity(0.12), in: Capsule())
        } else {
            Text("No active activity")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
