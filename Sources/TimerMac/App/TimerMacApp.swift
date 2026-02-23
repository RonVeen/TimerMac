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
            Picker("Default Activity Type", selection: $configuration.defaultActivityType) {
                ForEach(ActivityType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }

            Stepper(value: $configuration.defaultDurationMinutes, in: 5...480, step: 5) {
                Text("Default Duration: \(configuration.defaultDurationMinutes) minutes")
            }

            Picker("Rounding", selection: Binding(get: {
                configuration.roundingMinutes
            }, set: { newValue in
                configuration.roundingMinutes = newValue
            })) {
                ForEach(roundingOptions, id: \.self) { value in
                    Text(value == 0 ? "No rounding" : "\(value) minutes").tag(value)
                }
            }

            TextField("CSV Delimiter", text: $configuration.csvDelimiter)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 140)

            TextField("Default Start Time (HH:mm)", text: $configuration.defaultStartTime)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 180)
        }
        .padding()
    }
}
