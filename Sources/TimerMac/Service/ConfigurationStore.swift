import Foundation

final class ConfigurationStore: ObservableObject {
    @Published var defaultActivityType: ActivityType {
        didSet { save(key: Keys.defaultActivityType, value: defaultActivityType.rawValue) }
    }

    @Published var csvDelimiter: String {
        didSet { save(key: Keys.csvDelimiter, value: csvDelimiter) }
    }

    @Published var defaultDurationMinutes: Int {
        didSet { save(key: Keys.defaultDurationMinutes, value: defaultDurationMinutes) }
    }

    @Published var roundingMinutes: Int {
        didSet { save(key: Keys.roundingMinutes, value: roundingMinutes) }
    }

    @Published var defaultStartTime: String {
        didSet { save(key: Keys.defaultStartTime, value: defaultStartTime) }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let type = ActivityType(rawValue: userDefaults.string(forKey: Keys.defaultActivityType) ?? "") ?? .develop
        defaultActivityType = type
        csvDelimiter = userDefaults.string(forKey: Keys.csvDelimiter) ?? ","
        let duration = userDefaults.integer(forKey: Keys.defaultDurationMinutes)
        defaultDurationMinutes = duration > 0 ? duration : 60
        if userDefaults.object(forKey: Keys.roundingMinutes) == nil {
            roundingMinutes = 5
        } else {
            let stored = userDefaults.integer(forKey: Keys.roundingMinutes)
            roundingMinutes = max(0, stored)
        }
        defaultStartTime = userDefaults.string(forKey: Keys.defaultStartTime) ?? "09:00"
    }

    func defaultStartDate(for referenceDate: Date) -> Date {
        let components = defaultStartTime.split(separator: ":")
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        if components.count == 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            dateComponents.hour = hour
            dateComponents.minute = minute
        }
        return calendar.date(from: dateComponents) ?? referenceDate
    }

    private func save(key: String, value: Any) {
        userDefaults.setValue(value, forKey: key)
    }

    private enum Keys {
        static let defaultActivityType = "default.activity.type"
        static let csvDelimiter = "csv.delimiter"
        static let defaultDurationMinutes = "default.duration.minutes"
        static let roundingMinutes = "rounding.minutes"
        static let defaultStartTime = "default.start.time"
    }
}
