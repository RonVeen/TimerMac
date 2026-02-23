import Foundation
import SQLite3

protocol ActivityRepository {
    func save(activity: Activity) throws -> Activity
    func update(activity: Activity) throws -> Activity
    func delete(id: Int64) throws
    func findById(_ id: Int64) throws -> Activity?
    func findAll() throws -> [Activity]
    func findByStatus(_ status: ActivityStatus) throws -> [Activity]
    func findByDateRange(from: Date, to: Date) throws -> [Activity]
    func findByDate(_ date: Date) throws -> [Activity]
    func findLatestActivity(on date: Date) throws -> Activity?
    func updateStatus(current: ActivityStatus, newStatus: ActivityStatus, endTime: Date?) throws
}

final class SQLiteActivityRepository: ActivityRepository {
    private let database: SQLiteDatabase

    init(database: SQLiteDatabase = .shared) {
        self.database = database
    }

    func save(activity: Activity) throws -> Activity {
        var activity = activity
        let sql = """
        INSERT INTO activity (start_time, end_time, activity_type, status, description)
        VALUES (?, ?, ?, ?, ?)
        """

        try database.sync { db in
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(database.errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }

            bind(date: activity.startTime, to: statement, index: 1)
            bind(optionalDate: activity.endTime, to: statement, index: 2)
            bind(text: activity.activityType.rawValue, to: statement, index: 3)
            bind(text: activity.status.rawValue, to: statement, index: 4)
            bind(text: activity.description, to: statement, index: 5)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.executionFailed(database.errorMessage(for: db))
            }

            activity.id = sqlite3_last_insert_rowid(db)
        }

        return activity
    }

    func update(activity: Activity) throws -> Activity {
        let sql = """
        UPDATE activity
        SET start_time = ?, end_time = ?, activity_type = ?, status = ?, description = ?
        WHERE id = ?
        """

        try database.sync { db in
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(database.errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }

            bind(date: activity.startTime, to: statement, index: 1)
            bind(optionalDate: activity.endTime, to: statement, index: 2)
            bind(text: activity.activityType.rawValue, to: statement, index: 3)
            bind(text: activity.status.rawValue, to: statement, index: 4)
            bind(text: activity.description, to: statement, index: 5)
            sqlite3_bind_int64(statement, 6, activity.id)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.executionFailed(database.errorMessage(for: db))
            }
        }

        return activity
    }

    func delete(id: Int64) throws {
        let sql = "DELETE FROM activity WHERE id = ?"
        try database.sync { db in
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(database.errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }
            sqlite3_bind_int64(statement, 1, id)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.executionFailed(database.errorMessage(for: db))
            }
        }
    }

    func findById(_ id: Int64) throws -> Activity? {
        let sql = baseSelect + " WHERE id = ? LIMIT 1"
        return try fetchSingle(sql: sql) { statement in
            sqlite3_bind_int64(statement, 1, id)
        }
    }

    func findAll() throws -> [Activity] {
        let sql = baseSelect + " ORDER BY start_time ASC"
        return try fetchMultiple(sql: sql, configure: nil)
    }

    func findByStatus(_ status: ActivityStatus) throws -> [Activity] {
        let sql = baseSelect + " WHERE status = ? ORDER BY start_time ASC"
        return try fetchMultiple(sql: sql) { statement in
            bind(text: status.rawValue, to: statement, index: 1)
        }
    }

    func findByDateRange(from: Date, to: Date) throws -> [Activity] {
        let sql = baseSelect + " WHERE DATE(start_time) >= DATE(?) AND DATE(start_time) <= DATE(?) ORDER BY start_time ASC"
        return try fetchMultiple(sql: sql) { statement in
            bind(date: from, to: statement, index: 1)
            bind(date: to, to: statement, index: 2)
        }
    }

    func findByDate(_ date: Date) throws -> [Activity] {
        let sql = baseSelect + " WHERE DATE(start_time) = DATE(?) ORDER BY start_time ASC"
        return try fetchMultiple(sql: sql) { statement in
            bind(date: date, to: statement, index: 1)
        }
    }

    func findLatestActivity(on date: Date) throws -> Activity? {
        let sql = baseSelect + " WHERE DATE(start_time) = DATE(?) ORDER BY end_time DESC LIMIT 1"
        return try fetchSingle(sql: sql) { statement in
            bind(date: date, to: statement, index: 1)
        }
    }

    func updateStatus(current: ActivityStatus, newStatus: ActivityStatus, endTime: Date?) throws {
        let sql = "UPDATE activity SET status = ?, end_time = ? WHERE status = ?"
        try database.sync { db in
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(database.errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }
            bind(text: newStatus.rawValue, to: statement, index: 1)
            bind(optionalDate: endTime, to: statement, index: 2)
            bind(text: current.rawValue, to: statement, index: 3)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.executionFailed(database.errorMessage(for: db))
            }
        }
    }

    private var baseSelect: String {
        """
        SELECT id, start_time, end_time, activity_type, status, description
        FROM activity
        """
    }

    private func fetchMultiple(sql: String, configure: ((OpaquePointer?) -> Void)?) throws -> [Activity] {
        try database.sync { db in
            var results: [Activity] = []
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(database.errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }

            configure?(statement)

            while sqlite3_step(statement) == SQLITE_ROW {
                if let activity = mapActivity(from: statement) {
                    results.append(activity)
                }
            }
            return results
        }
    }

    private func fetchSingle(sql: String, configure: ((OpaquePointer?) -> Void)?) throws -> Activity? {
        try database.sync { db in
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(database.errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }

            configure?(statement)

            if sqlite3_step(statement) == SQLITE_ROW {
                return mapActivity(from: statement)
            }
            return nil
        }
    }

    private func mapActivity(from statement: OpaquePointer?) -> Activity? {
        let id = sqlite3_column_int64(statement, 0)
        guard let startString = columnText(statement, index: 1),
              let start = Date.fromISO8601(startString)
        else {
            return nil
        }
        let endString = columnText(statement, index: 2)
        let end = endString.flatMap { Date.fromISO8601($0) }
        let typeRaw = columnText(statement, index: 3) ?? ActivityType.general.rawValue
        let statusRaw = columnText(statement, index: 4) ?? ActivityStatus.completed.rawValue
        let description = columnText(statement, index: 5) ?? ""

        let type = ActivityType(rawValue: typeRaw) ?? .general
        let status = ActivityStatus(rawValue: statusRaw) ?? .completed

        return Activity(id: id,
                        startTime: start,
                        endTime: end,
                        activityType: type,
                        status: status,
                        description: description)
    }
}

protocol JobRepository {
    func save(job: Job) throws -> Job
    func delete(id: Int64) throws
    func findAll() throws -> [Job]
    func findById(_ id: Int64) throws -> Job?
}

final class SQLiteJobRepository: JobRepository {
    private let database: SQLiteDatabase

    init(database: SQLiteDatabase = .shared) {
        self.database = database
    }

    func save(job: Job) throws -> Job {
        var job = job
        if job.id == 0 {
            let sql = "INSERT INTO job (description) VALUES (?)"
            try database.sync { db in
                var statement: OpaquePointer?
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                    throw DatabaseError.preparationFailed(database.errorMessage(for: db))
                }
                defer { sqlite3_finalize(statement) }
                bind(text: job.description, to: statement, index: 1)
                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw DatabaseError.executionFailed(database.errorMessage(for: db))
                }
                job.id = sqlite3_last_insert_rowid(db)
            }
        } else {
            let sql = "UPDATE job SET description = ? WHERE id = ?"
            try database.sync { db in
                var statement: OpaquePointer?
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                    throw DatabaseError.preparationFailed(database.errorMessage(for: db))
                }
                defer { sqlite3_finalize(statement) }
                bind(text: job.description, to: statement, index: 1)
                sqlite3_bind_int64(statement, 2, job.id)
                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw DatabaseError.executionFailed(database.errorMessage(for: db))
                }
            }
        }
        return job
    }

    func delete(id: Int64) throws {
        let sql = "DELETE FROM job WHERE id = ?"
        try database.sync { db in
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(database.errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }
            sqlite3_bind_int64(statement, 1, id)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.executionFailed(database.errorMessage(for: db))
            }
        }
    }

    func findAll() throws -> [Job] {
        let sql = "SELECT id, description FROM job ORDER BY id ASC"
        return try database.sync { db in
            var results: [Job] = []
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(database.errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let description = columnText(statement, index: 1) ?? ""
                results.append(Job(id: id, description: description))
            }
            return results
        }
    }

    func findById(_ id: Int64) throws -> Job? {
        let sql = "SELECT id, description FROM job WHERE id = ? LIMIT 1"
        return try database.sync { db in
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(database.errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }
            sqlite3_bind_int64(statement, 1, id)
            if sqlite3_step(statement) == SQLITE_ROW {
                let identifier = sqlite3_column_int64(statement, 0)
                let description = columnText(statement, index: 1) ?? ""
                return Job(id: identifier, description: description)
            }
            return nil
        }
    }
}

private func bind(text: String, to statement: OpaquePointer?, index: Int32) {
    sqlite3_bind_text(statement, index, text, -1, SQLITE_TRANSIENT)
}

private func bind(date: Date, to statement: OpaquePointer?, index: Int32) {
    bind(text: date.iso8601String(), to: statement, index: index)
}

private func bind(optionalDate: Date?, to statement: OpaquePointer?, index: Int32) {
    if let date = optionalDate {
        bind(date: date, to: statement, index: index)
    } else {
        sqlite3_bind_null(statement, index)
    }
}

private func columnText(_ statement: OpaquePointer?, index: Int32) -> String? {
    guard let value = sqlite3_column_text(statement, index) else { return nil }
    return String(cString: value)
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
