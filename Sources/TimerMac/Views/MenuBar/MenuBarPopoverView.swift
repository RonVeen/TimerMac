import SwiftUI
#if os(macOS)
import AppKit
#endif

struct MenuBarPopoverView: View {
    @ObservedObject var viewModel: TimerViewModel
    @EnvironmentObject var configuration: ConfigurationStore
    @Environment(\.openWindow) private var openWindow
    @State private var quickStartText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ActiveStatusSection(activity: viewModel.activeActivity,
                               onStop: { viewModel.stopActivity() })

            Divider()

            QuickStartSection(text: $quickStartText,
                             isSwitching: viewModel.activeActivity != nil,
                             onStart: startQuickActivity)

            Divider()

            JobsQuickListSection(jobs: Array(viewModel.jobs.prefix(5)),
                                 onStart: startFromJob)

            Divider()

            MenuBarFooterSection(onOpen: openMainWindow,
                                onQuit: { NSApp.terminate(nil) })
        }
        .padding(12)
        .frame(width: 280)
    }

    private func startQuickActivity() {
        let trimmed = quickStartText.trimmed()
        guard !trimmed.isBlank else { return }
        viewModel.startActivity(description: trimmed,
                                type: configuration.defaultActivityType,
                                startDate: Date(),
                                connectToPrevious: false)
        quickStartText = ""
    }

    private func startFromJob(_ job: Job) {
        viewModel.startFromJob(job: job,
                               type: configuration.defaultActivityType,
                               startDate: Date())
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct ActiveStatusSection: View {
    let activity: Activity?
    let onStop: () -> Void

    var body: some View {
        if let activity {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                    .font(.headline)
                    .lineLimit(1)
                TimelineView(.periodic(from: activity.startTime, by: 30)) { _ in
                    Text(activity.durationText)
                        .foregroundStyle(.secondary)
                }
                Button("Stop", action: onStop)
                    .buttonStyle(.bordered)
                    .tint(.red)
            }
        } else {
            Text("No active activity")
                .foregroundStyle(.secondary)
        }
    }
}

private struct QuickStartSection: View {
    @Binding var text: String
    let isSwitching: Bool
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quick start")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                TextField("What are you working on?", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(onStart)
                Button(isSwitching ? "Switch" : "Start", action: onStart)
                    .disabled(text.isBlank)
            }
        }
    }
}

private struct JobsQuickListSection: View {
    let jobs: [Job]
    let onStart: (Job) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Jobs")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if jobs.isEmpty {
                Text("No saved jobs")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(jobs) { job in
                    Button(job.description) { onStart(job) }
                        .buttonStyle(.plain)
                        .lineLimit(1)
                }
            }
        }
    }
}

private struct MenuBarFooterSection: View {
    let onOpen: () -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack {
            Button("Open TimerMac", action: onOpen)
            Spacer()
            Button("Quit", action: onQuit)
        }
    }
}
