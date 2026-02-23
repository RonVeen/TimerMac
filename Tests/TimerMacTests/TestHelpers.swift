import Foundation
@testable import TimerMac

final class InMemoryActivityRepository: ActivityRepository {
    private var storage: [Activity] = []
    private var nextId: Int64 = 1

    func save(activity: Activity) throws -> Activity {
        var copy = activity
        copy.id = nextId
        nextId += 1
        storage.append(copy)
        return copy
    }

    func update(activity: Activity) throws -> Activity {
        guard let index = storage.firstIndex(where: { $0.id == activity.id }) else {
            throw NSError(domain: "InMemoryActivityRepository", code: 1)
        }
        storage[index] = activity
        return activity
    }

    func delete(id: Int64) throws {
        storage.removeAll { $0.id == id }
    }

    func findById(_ id: Int64) throws -> Activity? {
        storage.first { $0.id == id }
    }

    func findAll() throws -> [Activity] {
        storage.sorted { $0.startTime < $1.startTime }
    }

    func findByStatus(_ status: ActivityStatus) throws -> [Activity] {
        storage.filter { $0.status == status }
    }

    func findByDateRange(from: Date, to: Date) throws -> [Activity] {
        storage.filter { activity in
            activity.startTime >= from && activity.startTime <= to
        }
    }

    func findByDate(_ date: Date) throws -> [Activity] {
        let calendar = Calendar.current
        return storage.filter { activity in
            calendar.isDate(activity.startTime, inSameDayAs: date)
        }
    }

    func findLatestActivity(on date: Date) throws -> Activity? {
        let calendar = Calendar.current
        return storage
            .filter { calendar.isDate($0.startTime, inSameDayAs: date) }
            .sorted { ($0.endTime ?? Date.distantPast) < ($1.endTime ?? Date.distantPast) }
            .last
    }

    func updateStatus(current: ActivityStatus, newStatus: ActivityStatus, endTime: Date?) throws {
        storage = storage.map { activity in
            guard activity.status == current else { return activity }
            return Activity(id: activity.id,
                            startTime: activity.startTime,
                            endTime: endTime ?? activity.endTime,
                            activityType: activity.activityType,
                            status: newStatus,
                            description: activity.description)
        }
    }
}

extension ConfigurationStore {
    static func testInstance(rounding: Int = 5, duration: Int = 60) -> ConfigurationStore {
        let defaults = UserDefaults(suiteName: "TimerMacTests.\(UUID().uuidString)")!
        let store = ConfigurationStore(userDefaults: defaults)
        store.roundingMinutes = rounding
        store.defaultDurationMinutes = duration
        return store
    }
}
