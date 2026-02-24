import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct TimerMacApp: App {
    @StateObject private var configuration: ConfigurationStore
    @StateObject private var viewModel: TimerViewModel

    init() {
#if os(macOS)
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
#endif
        let configuration = ConfigurationStore()
        let activityService = ActivityService(configuration: configuration)
        let jobService = JobService()
        _configuration = StateObject(wrappedValue: configuration)
        _viewModel = StateObject(wrappedValue: TimerViewModel(activityService: activityService,
                                                              jobService: jobService,
                                                              configuration: configuration))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environmentObject(configuration)
        }
        .commands {
            ActionsCommands()
        }
        Settings {
            SettingsView(configuration: configuration)
                .padding(24)
                .frame(width: 420)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var configuration: ConfigurationStore
    private let roundingOptions = [0, 1, 5, 10, 15, 30, 60]

    var body: some View {
        Form {
            VStack(spacing: 16) {
                Section(header: Text("Defaults").font(.headline)) {
                    Picker("Default Activity Type", selection: $configuration.defaultActivityType) {
                        ForEach(ActivityType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Stepper(value: $configuration.defaultDurationMinutes, in: 5...480, step: 5) {
                        Text("Default Duration: \(configuration.defaultDurationMinutes) minutes")
                    }

                    TextField("Default Start Time (HH:mm)", text: $configuration.defaultStartTime)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                Section(header: Text("Exporting").font(.headline)) {
                    TextField("CSV Delimiter", text: $configuration.csvDelimiter)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 140)
                }

                Divider()

                Section(header: Text("Time").font(.headline)) {
                    Picker("Rounding", selection: $configuration.roundingMinutes) {
                        ForEach(roundingOptions, id: \.self) { value in
                            Text(value == 0 ? "No rounding" : "\(value) minutes").tag(value)
                        }
                    }
                }
            }
        }
        .padding()
    }
}
