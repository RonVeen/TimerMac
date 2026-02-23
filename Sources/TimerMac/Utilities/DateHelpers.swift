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
        isoFormatter().string(from: self)
    }

    static func fromISO8601(_ value: String) -> Date? {
        isoFormatter().date(from: value)
    }
}

private func isoFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}
