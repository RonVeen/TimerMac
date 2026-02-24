import Foundation
import SQLite3

enum DatabaseError: LocalizedError {
    case openFailed(String)
    case preparationFailed(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .openFailed(let message):
            return "Failed to open database: \(message)"
        case .preparationFailed(let message):
            return "Failed to prepare statement: \(message)"
        case .executionFailed(let message):
            return "Failed to execute statement: \(message)"
        }
    }
}

final class SQLiteDatabase {
    static let shared = SQLiteDatabase()

    let databaseURL: URL
    private let dbPointer: OpaquePointer?
    private let queue = DispatchQueue(label: "org.veenix.timer.database", qos: .userInitiated)

    private init() {
        let fileManager = FileManager.default
        do {
            let documentsDirectory = try fileManager.url(for: .documentDirectory,
                                                        in: .userDomainMask,
                                                        appropriateFor: nil,
                                                        create: true)
            databaseURL = documentsDirectory.appendingPathComponent("timer.db")
        } catch {
            fatalError("Unable to determine database URL: \(error.localizedDescription)")
        }

        var pointer: OpaquePointer?
        let openStatus = sqlite3_open(databaseURL.path, &pointer)
        guard openStatus == SQLITE_OK, let pointer else {
            fatalError("Unable to open SQLite database")
        }
        dbPointer = pointer
        do {
            try createTables()
        } catch {
            fatalError("Failed to create tables: \(error.localizedDescription)")
        }
    }

    deinit {
        sqlite3_close(dbPointer)
    }

    func sync<T>(_ block: (OpaquePointer?) throws -> T) rethrows -> T {
        try queue.sync {
            try block(dbPointer)
        }
    }

    private func createTables() throws {
        let createActivity = """
        CREATE TABLE IF NOT EXISTS activity (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time TEXT NOT NULL,
            end_time TEXT,
            activity_type TEXT NOT NULL,
            status TEXT NOT NULL,
            description TEXT
        );
        """

        let createJob = """
        CREATE TABLE IF NOT EXISTS job (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL
        );
        """

        try execute(sql: createActivity)
        try execute(sql: createJob)
    }

    func execute(sql: String) throws {
        try sync { db in
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw DatabaseError.preparationFailed(errorMessage(for: db))
            }
            defer { sqlite3_finalize(statement) }
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.executionFailed(errorMessage(for: db))
            }
        }
    }

    func errorMessage(for db: OpaquePointer?) -> String {
        guard let db else { return "Unknown" }
        if let cString = sqlite3_errmsg(db) {
            return String(cString: cString)
        }
        return "Unknown"
    }
}

extension SQLiteDatabase: @unchecked Sendable {}
