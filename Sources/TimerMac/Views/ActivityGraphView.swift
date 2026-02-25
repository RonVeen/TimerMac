import SwiftUI

struct ActivityGraphPopover: View {
    let summaries: [ActivityGraphSummary]
    @State private var showPercentages = false

    private var legendTypes: [ActivityType] {
        ActivityType.allCases
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Breakdown")
                .font(.headline)

            HStack(alignment: .top, spacing: 24) {
                ForEach(summaries) { summary in
                    VStack(spacing: 12) {
                        DonutChartView(segments: summary.segments, showPercentages: showPercentages)
                            .frame(width: 130, height: 130)
                        Text(summary.title)
                            .font(.subheadline)
                        Text(summary.totalMinutes > 0 ? "\(summary.totalMinutes) min total" : "No data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            HStack {
                Text("Legend")
                    .font(.subheadline)
                Spacer()
                Toggle("Show percentages", isOn: $showPercentages)
                    .toggleStyle(.switch)
            }
            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(legendTypes.indices.filter { $0.isMultiple(of: 2) }, id: \.self) { index in
                        legendRow(for: legendTypes[index])
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(legendTypes.indices.filter { !$0.isMultiple(of: 2) }, id: \.self) { index in
                        legendRow(for: legendTypes[index])
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    private func legendRow(for type: ActivityType) -> some View {
        HStack {
            Circle()
                .fill(type.color)
                .frame(width: 12, height: 12)
            Text(type.displayName)
                .font(.caption)
        }
    }
}

private struct DonutChartView: View {
    let segments: [ActivityGraphSegment]
    let showPercentages: Bool

    private var ratios: [DonutSlice] {
        let total = max(segments.reduce(0) { $0 + $1.minutes }, 1)
        var start: CGFloat = 0
        return segments.map { segment in
            let fraction = CGFloat(segment.minutes) / CGFloat(total)
            let slice = DonutSlice(id: segment.id, color: segment.color, start: start, end: start + fraction)
            start += fraction
            return slice
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let minSide = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let labelRadius = minSide / 2 - 18
            ZStack {
                if segments.isEmpty {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 16)
                    Text("No Data")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(ratios) { slice in
                        Circle()
                            .trim(from: slice.start, to: slice.end)
                            .stroke(slice.color, lineWidth: 16)
                            .rotationEffect(.degrees(-90))
                        if showPercentages && slice.fraction >= 0.12 {
                            Text("\(Int(slice.fraction * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .position(position(for: slice, center: center, radius: labelRadius))
                        }
                    }
                    let total = segments.reduce(0) { $0 + $1.minutes }
                    Text("\(total) m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func position(for slice: DonutSlice, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = (slice.start + slice.end) / 2 * 360 - 90
        let radians = angle * .pi / 180
        return CGPoint(x: center.x + radius * cos(radians),
                       y: center.y + radius * sin(radians))
    }
}

private struct DonutSlice: Identifiable {
    let id: UUID
    let color: Color
    let start: CGFloat
    let end: CGFloat
    var fraction: CGFloat { end - start }
}
