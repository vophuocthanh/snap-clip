import Foundation
import SQLite3

/// SQLITE_TRANSIENT: yêu cầu SQLite tự copy buffer khi bind — an toàn với chuỗi Swift tạm.
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

enum SQLiteError: Error, CustomStringConvertible {
    case open(String)
    case prepare(String)
    case step(String)
    case bind(String)

    var description: String {
        switch self {
        case .open(let m): return "SQLite open error: \(m)"
        case .prepare(let m): return "SQLite prepare error: \(m)"
        case .step(let m): return "SQLite step error: \(m)"
        case .bind(let m): return "SQLite bind error: \(m)"
        }
    }
}

/// Wrapper mỏng quanh SQLite C API.
///
/// Mọi truy cập được serialize qua một `DispatchQueue` nội bộ để an toàn khi
/// monitor (nền) ghi và UI (main) đọc đồng thời. Đây là đánh đổi đơn giản &
/// đủ nhanh cho khối lượng của một clipboard manager (ghi rời rạc, đọc nhẹ).
final class SQLiteDatabase: @unchecked Sendable {
    private var handle: OpaquePointer?
    private let queue = DispatchQueue(label: "com.snapclip.sqlite")

    /// Đường dẫn file db đang mở (dùng cho backup/log).
    let path: String

    init(path: String) throws {
        self.path = path
        var db: OpaquePointer?
        // FULLMUTEX: an toàn đa luồng ở tầng SQLite; ta vẫn tự serialize để đơn giản hoá.
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK, let db else {
            let msg = db != nil ? String(cString: sqlite3_errmsg(db)) : "unknown"
            if let db { sqlite3_close_v2(db) }
            throw SQLiteError.open(msg)
        }
        self.handle = db
        // Bật WAL cho hiệu năng ghi tốt và đọc không chặn ghi.
        try exec("PRAGMA journal_mode = WAL;")
        try exec("PRAGMA synchronous = NORMAL;")
        try exec("PRAGMA foreign_keys = ON;")
    }

    deinit {
        if let handle { sqlite3_close_v2(handle) }
    }

    private var errorMessage: String {
        guard let handle else { return "no handle" }
        return String(cString: sqlite3_errmsg(handle))
    }

    /// Thực thi câu SQL không trả về dữ liệu (DDL, PRAGMA...).
    func exec(_ sql: String) throws {
        try queue.sync {
            guard sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK else {
                throw SQLiteError.step(errorMessage)
            }
        }
    }

    /// Thực thi câu ghi (INSERT/UPDATE/DELETE) có tham số bind, không đọc kết quả.
    func execute(_ sql: String, bind: ((OpaquePointer) throws -> Void)? = nil) throws {
        let _: [Int] = try run(sql, bind: bind, read: nil)
    }

    /// Chạy một câu prepared statement. `bind` gán tham số, `read` đọc từng dòng.
    /// Trả về mảng kết quả do `read` sinh ra (rỗng nếu là câu ghi).
    @discardableResult
    func run<T>(
        _ sql: String,
        bind: ((OpaquePointer) throws -> Void)? = nil,
        read: ((OpaquePointer) throws -> T)? = nil
    ) throws -> [T] {
        try queue.sync {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw SQLiteError.prepare(errorMessage)
            }
            defer { sqlite3_finalize(stmt) }
            if let bind, let stmt { try bind(stmt) }

            var results: [T] = []
            while true {
                let rc = sqlite3_step(stmt)
                if rc == SQLITE_ROW {
                    if let read, let stmt { results.append(try read(stmt)) }
                } else if rc == SQLITE_DONE {
                    break
                } else {
                    throw SQLiteError.step(errorMessage)
                }
            }
            return results
        }
    }
}

// MARK: - Bind / column helpers

extension OpaquePointer {
    func bindText(_ value: String, at index: Int32) {
        sqlite3_bind_text(self, index, value, -1, SQLITE_TRANSIENT)
    }

    func bindTextOrNull(_ value: String?, at index: Int32) {
        if let value {
            sqlite3_bind_text(self, index, value, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(self, index)
        }
    }

    func bindInt(_ value: Int, at index: Int32) {
        sqlite3_bind_int64(self, index, Int64(value))
    }

    func bindDouble(_ value: Double, at index: Int32) {
        sqlite3_bind_double(self, index, value)
    }

    func bindBlobOrNull(_ value: Data?, at index: Int32) {
        if let value, !value.isEmpty {
            _ = value.withUnsafeBytes { raw in
                sqlite3_bind_blob(self, index, raw.baseAddress, Int32(value.count), SQLITE_TRANSIENT)
            }
        } else {
            sqlite3_bind_null(self, index)
        }
    }

    func columnBlobOrNil(_ index: Int32) -> Data? {
        guard sqlite3_column_type(self, index) != SQLITE_NULL else { return nil }
        let count = Int(sqlite3_column_bytes(self, index))
        guard count > 0, let ptr = sqlite3_column_blob(self, index) else { return nil }
        return Data(bytes: ptr, count: count)
    }

    func columnText(_ index: Int32) -> String {
        guard let c = sqlite3_column_text(self, index) else { return "" }
        return String(cString: c)
    }

    func columnTextOrNil(_ index: Int32) -> String? {
        guard sqlite3_column_type(self, index) != SQLITE_NULL,
              let c = sqlite3_column_text(self, index) else { return nil }
        return String(cString: c)
    }

    func columnInt(_ index: Int32) -> Int {
        Int(sqlite3_column_int64(self, index))
    }

    func columnDouble(_ index: Int32) -> Double {
        sqlite3_column_double(self, index)
    }
}
