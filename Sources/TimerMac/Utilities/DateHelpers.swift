import Foundation

enum DateFormatters {
    static func date() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    static func time() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    static func dateTime() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

enum ActivityDurationFormatter {
    static func totalText(for activities: [Activity], referenceDate: Date = Date()) -> String {
        let totalSeconds = activities.reduce(0.0) { partial, activity in
            let end = activity.endTime ?? (activity.status == .active ? referenceDate : activity.startTime)
            let delta = max(0, end.timeIntervalSince(activity.startTime))
            return partial + delta
        }

        let totalMinutes = Int(totalSeconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m (\(totalMinutes) min)"
        } else {
            return "\(totalMinutes) min"
        }
    }
}

extension Date {
    func startOfDay(in calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }

    func endOfDay(in calendar: Calendar = .current) -> Date {
        let start = startOfDay(in: calendar)
        let components = DateComponents(day: 1, second: -1)
        return calendar.date(byAdding: components, to: start) ?? self
    }

    func roundedUp(toMinutes interval: Int) -> Date {
        guard interval > 1 else { return self }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        guard let base = calendar.date(from: components) else { return self }
        let minute = components.minute ?? 0
        let remainder = minute % interval
        if remainder == 0 {
            return base
        }
        let minutesToAdd = interval - remainder
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: base) ?? self
    }

    func iso8601String() -> String {
        Self.isoFormatter().string(from: self)
    }

    static func fromISO8601(_ value: String) -> Date? {
        for formatter in Self.isoFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private static let isoFormatters: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm"
        ]
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
    }()

    private static func isoFormatter() -> DateFormatter {
        isoFormatters[0]
    }
}
