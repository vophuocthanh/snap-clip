import Foundation

/// Cài đặt `ClipboardRepository` trên SQLite.
///
/// Schema versioning đơn giản qua `PRAGMA user_version` để hỗ trợ migration
/// tăng dần trong tương lai mà không phá dữ liệu người dùng.
final class SQLiteClipboardRepository: ClipboardRepository, @unchecked Sendable {
    private let db: SQLiteDatabase
    private static let currentSchemaVersion = 3

    init(db: SQLiteDatabase) throws {
        self.db = db
        try migrate()
    }

    /// Tạo repository trỏ tới thư mục Application Support của app.
    static func makeDefault() throws -> SQLiteClipboardRepository {
        let fm = FileManager.default
        let base = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("CopyClipPro", isDirectory: true)
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        let dbURL = base.appendingPathComponent("history.sqlite")
        let db = try SQLiteDatabase(path: dbURL.path)
        return try SQLiteClipboardRepository(db: db)
    }

    // MARK: - Migration

    private func migrate() throws {
        let version = try currentUserVersion()
        if version < 1 {
            try db.exec(
                """
                CREATE TABLE IF NOT EXISTS clipboard_items (
                    id TEXT PRIMARY KEY NOT NULL,
                    content TEXT NOT NULL,
                    content_hash TEXT NOT NULL,
                    type TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    is_pinned INTEGER NOT NULL DEFAULT 0,
                    is_favorite INTEGER NOT NULL DEFAULT 0,
                    source_bundle_id TEXT,
                    source_app_name TEXT
                );
                CREATE INDEX IF NOT EXISTS idx_items_created_at
                    ON clipboard_items (created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_items_hash
                    ON clipboard_items (content_hash);
                CREATE INDEX IF NOT EXISTS idx_items_flags
                    ON clipboard_items (is_pinned, is_favorite);
                """
            )
            try db.exec("PRAGMA user_version = 1;")
        }
        if version < 2 {
            // Thêm cột lưu ảnh gốc (PNG) và thumbnail cho tính năng lưu hình ảnh.
            try db.exec("ALTER TABLE clipboard_items ADD COLUMN image_data BLOB;")
            try db.exec("ALTER TABLE clipboard_items ADD COLUMN thumbnail_data BLOB;")
            try db.exec("PRAGMA user_version = 2;")
        }
        if version < 3 {
            // Sprint 4: rich text RTF, file bookmark/path/UTI.
            try db.exec("ALTER TABLE clipboard_items ADD COLUMN rich_text_data BLOB;")
            try db.exec("ALTER TABLE clipboard_items ADD COLUMN file_bookmark BLOB;")
            try db.exec("ALTER TABLE clipboard_items ADD COLUMN file_path TEXT;")
            try db.exec("ALTER TABLE clipboard_items ADD COLUMN file_uti TEXT;")
            try db.exec("PRAGMA user_version = 3;")
        }
    }

    private func currentUserVersion() throws -> Int {
        let rows = try db.run("PRAGMA user_version;", read: { $0.columnInt(0) })
        return rows.first ?? 0
    }

    // MARK: - ClipboardRepository

    @discardableResult
    func insert(_ item: ClipboardItem) throws -> ClipboardItem {
        // Dedup: nếu nội dung trùng bản ghi đã có → nâng thời gian, xoá bản cũ, chèn mới.
        let existing = try db.run(
            "SELECT id FROM clipboard_items WHERE content_hash = ? LIMIT 1;",
            bind: { $0.bindText(item.contentHash, at: 1) },
            read: { $0.columnText(0) }
        )
        if let oldId = existing.first {
            try db.execute(
                "UPDATE clipboard_items SET created_at = ? WHERE id = ?;",
                bind: {
                    $0.bindDouble(Date().timeIntervalSince1970, at: 1)
                    $0.bindText(oldId, at: 2)
                }
            )
            return item
        }

        try db.execute(
            """
            INSERT INTO clipboard_items
                (id, content, content_hash, type, created_at,
                 is_pinned, is_favorite, source_bundle_id, source_app_name,
                 image_data, thumbnail_data, rich_text_data,
                 file_bookmark, file_path, file_uti)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bind: { stmt in
                stmt.bindText(item.id.uuidString, at: 1)
                stmt.bindText(item.content, at: 2)
                stmt.bindText(item.contentHash, at: 3)
                stmt.bindText(item.type.rawValue, at: 4)
                stmt.bindDouble(item.createdAt.timeIntervalSince1970, at: 5)
                stmt.bindInt(item.isPinned ? 1 : 0, at: 6)
                stmt.bindInt(item.isFavorite ? 1 : 0, at: 7)
                stmt.bindTextOrNull(item.sourceAppBundleId, at: 8)
                stmt.bindTextOrNull(item.sourceAppName, at: 9)
                stmt.bindBlobOrNull(item.imageData, at: 10)
                stmt.bindBlobOrNull(item.thumbnailData, at: 11)
                stmt.bindBlobOrNull(item.richTextData, at: 12)
                stmt.bindBlobOrNull(item.fileBookmark, at: 13)
                stmt.bindTextOrNull(item.filePath, at: 14)
                stmt.bindTextOrNull(item.fileUTI, at: 15)
            }
        )
        return item
    }

    func imageData(id: UUID) throws -> Data? {
        let rows = try db.run(
            "SELECT image_data FROM clipboard_items WHERE id = ? LIMIT 1;",
            bind: { $0.bindText(id.uuidString, at: 1) },
            read: { $0.columnBlobOrNil(0) }
        )
        return rows.first ?? nil
    }

    func richTextData(id: UUID) throws -> Data? {
        let rows = try db.run(
            "SELECT rich_text_data FROM clipboard_items WHERE id = ? LIMIT 1;",
            bind: { $0.bindText(id.uuidString, at: 1) },
            read: { $0.columnBlobOrNil(0) }
        )
        return rows.first ?? nil
    }

    func resolveFileURL(id: UUID) throws -> URL? {
        let rows = try db.run(
            "SELECT file_bookmark, file_path FROM clipboard_items WHERE id = ? LIMIT 1;",
            bind: { $0.bindText(id.uuidString, at: 1) },
            read: { (stmt) -> (Data?, String?) in
                (stmt.columnBlobOrNil(0), stmt.columnTextOrNil(1))
            }
        )
        guard let (bookmarkData, path) = rows.first else { return nil }
        // Thử giải bookmark trước; fallback dùng đường dẫn
        if let bookmarkData {
            var stale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) {
                return url
            }
        }
        return path.flatMap { URL(fileURLWithPath: $0) }
    }

    func fetch(_ query: HistoryQuery) throws -> [ClipboardItem] {
        var sql = "SELECT id, content, content_hash, type, created_at, is_pinned, is_favorite, source_bundle_id, source_app_name, thumbnail_data, file_path, file_uti FROM clipboard_items"
        var conditions: [String] = []
        if !query.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            conditions.append("content LIKE ? ESCAPE '\\'")
        }
        if query.onlyFavorites {
            conditions.append("is_favorite = 1")
        }
        if !conditions.isEmpty {
            sql += " WHERE " + conditions.joined(separator: " AND ")
        }
        // Pinned lên đầu, rồi mới nhất trước.
        sql += " ORDER BY is_pinned DESC, created_at DESC LIMIT ? OFFSET ?;"

        return try db.run(
            sql,
            bind: { stmt in
                var idx: Int32 = 1
                let trimmed = query.searchText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    let escaped = trimmed
                        .replacingOccurrences(of: "\\", with: "\\\\")
                        .replacingOccurrences(of: "%", with: "\\%")
                        .replacingOccurrences(of: "_", with: "\\_")
                    stmt.bindText("%\(escaped)%", at: idx); idx += 1
                }
                stmt.bindInt(query.limit, at: idx); idx += 1
                stmt.bindInt(query.offset, at: idx)
            },
            read: { Self.decode($0) }
        )
    }

    func setPinned(_ isPinned: Bool, id: UUID) throws {
        try db.execute(
            "UPDATE clipboard_items SET is_pinned = ? WHERE id = ?;",
            bind: {
                $0.bindInt(isPinned ? 1 : 0, at: 1)
                $0.bindText(id.uuidString, at: 2)
            }
        )
    }

    func setFavorite(_ isFavorite: Bool, id: UUID) throws {
        try db.execute(
            "UPDATE clipboard_items SET is_favorite = ? WHERE id = ?;",
            bind: {
                $0.bindInt(isFavorite ? 1 : 0, at: 1)
                $0.bindText(id.uuidString, at: 2)
            }
        )
    }

    func delete(id: UUID) throws {
        try db.execute(
            "DELETE FROM clipboard_items WHERE id = ?;",
            bind: { $0.bindText(id.uuidString, at: 1) }
        )
    }

    func clear(keepProtected: Bool) throws {
        if keepProtected {
            try db.exec("DELETE FROM clipboard_items WHERE is_pinned = 0 AND is_favorite = 0;")
        } else {
            try db.exec("DELETE FROM clipboard_items;")
        }
    }

    func count() throws -> Int {
        let rows = try db.run("SELECT COUNT(*) FROM clipboard_items;", read: { $0.columnInt(0) })
        return rows.first ?? 0
    }

    func enforceRetention(maxItems: Int) throws {
        // Xoá những bản ghi thường (không pin/fav) nằm ngoài top `maxItems` mới nhất.
        try db.execute(
            """
            DELETE FROM clipboard_items
            WHERE is_pinned = 0 AND is_favorite = 0
              AND id NOT IN (
                SELECT id FROM clipboard_items
                WHERE is_pinned = 0 AND is_favorite = 0
                ORDER BY created_at DESC
                LIMIT ?
              );
            """,
            bind: { $0.bindInt(maxItems, at: 1) }
        )
    }

    // MARK: - Row decoding

    private static func decode(_ stmt: OpaquePointer) -> ClipboardItem {
        ClipboardItem(
            id: UUID(uuidString: stmt.columnText(0)) ?? UUID(),
            content: stmt.columnText(1),
            contentHash: stmt.columnText(2),
            type: ClipboardContentType(rawValue: stmt.columnText(3)) ?? .text,
            createdAt: Date(timeIntervalSince1970: stmt.columnDouble(4)),
            isPinned: stmt.columnInt(5) == 1,
            isFavorite: stmt.columnInt(6) == 1,
            sourceAppBundleId: stmt.columnTextOrNil(7),
            sourceAppName: stmt.columnTextOrNil(8),
            imageData: nil,
            thumbnailData: stmt.columnBlobOrNil(9),
            filePath: stmt.columnTextOrNil(10),
            fileUTI: stmt.columnTextOrNil(11)
        )
    }
}
