// DatabaseManager.swift
// Comic Viewer – Local SQLite Database Manager
//
// Provides offline caching of manga data and reading progress
// using SQLite3 directly (no third-party dependencies).

import Foundation
import SQLite3

/// Manages a local SQLite database for offline caching and progress tracking.
final class DatabaseManager {
    /// File path of the SQLite database
    private let dbPath: String

    /// SQLite database pointer
    private var db: OpaquePointer?

    // MARK: - Initialization

    /// Initialize the database manager with default app-support path.
    init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        // Ensure the directory exists
        try? fileManager.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )

        self.dbPath = appSupport
            .appendingPathComponent("comicviewer.sqlite")
            .path

        openDatabase()
        createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Connection

    /// Open the SQLite database file.
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("⚠️ DatabaseManager: Failed to open database at \(dbPath)")
        }
    }

    /// Execute a SQL statement that doesn't return results.
    private func execute(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            if let msg = errorMessage {
                print("⚠️ SQL Error: \(String(cString: msg))")
                sqlite3_free(msg)
            }
        }
    }

    // MARK: - Schema

    /// Create database tables if they don't exist.
    private func createTables() {
        let sql = """
        CREATE TABLE IF NOT EXISTS cached_mangas (
            id              INTEGER PRIMARY KEY,
            title           TEXT NOT NULL,
            author          TEXT,
            description     TEXT,
            cover_path      TEXT,
            source_id       INTEGER NOT NULL,
            total_chapters  INTEGER NOT NULL DEFAULT 0,
            cached_at       TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS reading_progress (
            manga_id        INTEGER PRIMARY KEY,
            chapter_id      INTEGER NOT NULL,
            current_page    INTEGER NOT NULL DEFAULT 0,
            total_pages     INTEGER NOT NULL DEFAULT 0,
            last_read_at    TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS server_config (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        """
        execute(sql)
    }

    // MARK: - Reading Progress

    /// Save or update reading progress for a manga.
    ///
    /// - Parameters:
    ///   - mangaId: The manga identifier.
    ///   - chapterId: The current chapter identifier.
    ///   - currentPage: The current page number (0-indexed).
    ///   - totalPages: Total pages in the current chapter.
    func saveProgress(
        mangaId: Int,
        chapterId: Int,
        currentPage: Int,
        totalPages: Int
    ) {
        let sql = """
        INSERT INTO reading_progress
            (manga_id, chapter_id, current_page, total_pages, last_read_at)
        VALUES (?, ?, ?, ?, datetime('now'))
        ON CONFLICT(manga_id) DO UPDATE SET
            chapter_id   = excluded.chapter_id,
            current_page = excluded.current_page,
            total_pages  = excluded.total_pages,
            last_read_at = datetime('now');
        """

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK
        else { return }

        sqlite3_bind_int(statement, 1, Int32(mangaId))
        sqlite3_bind_int(statement, 2, Int32(chapterId))
        sqlite3_bind_int(statement, 3, Int32(currentPage))
        sqlite3_bind_int(statement, 4, Int32(totalPages))

        sqlite3_step(statement)
    }

    /// Retrieve reading progress for a specific manga.
    ///
    /// - Parameter mangaId: The manga identifier.
    /// - Returns: A `ReadingProgress` if found, nil otherwise.
    func getProgress(mangaId: Int) -> ReadingProgress? {
        let sql = """
        SELECT manga_id, chapter_id, current_page, total_pages, last_read_at
        FROM reading_progress
        WHERE manga_id = ?;
        """

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK
        else { return nil }

        sqlite3_bind_int(statement, 1, Int32(mangaId))

        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }

        return ReadingProgress(
            id: nil,
            mangaId: Int(sqlite3_column_int(statement, 0)),
            chapterId: Int(sqlite3_column_int(statement, 1)),
            currentPage: Int(sqlite3_column_int(statement, 2)),
            totalPages: Int(sqlite3_column_int(statement, 3)),
            lastReadAt: columnText(statement, index: 4)
        )
    }

    /// Retrieve all reading progress records, ordered by most recent.
    ///
    /// - Returns: Array of `ReadingProgress` records.
    func getAllProgress() -> [ReadingProgress] {
        let sql = """
        SELECT manga_id, chapter_id, current_page, total_pages, last_read_at
        FROM reading_progress
        ORDER BY last_read_at DESC;
        """

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK
        else { return [] }

        var results: [ReadingProgress] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            results.append(ReadingProgress(
                id: nil,
                mangaId: Int(sqlite3_column_int(statement, 0)),
                chapterId: Int(sqlite3_column_int(statement, 1)),
                currentPage: Int(sqlite3_column_int(statement, 2)),
                totalPages: Int(sqlite3_column_int(statement, 3)),
                lastReadAt: columnText(statement, index: 4)
            ))
        }
        return results
    }

    // MARK: - Cached Mangas

    /// Cache a manga record locally for offline access.
    ///
    /// - Parameter manga: The manga to cache.
    func cacheManga(_ manga: Manga) {
        let sql = """
        INSERT OR REPLACE INTO cached_mangas
            (id, title, author, description, cover_path, source_id,
             total_chapters, cached_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'));
        """

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK
        else { return }

        sqlite3_bind_int(statement, 1, Int32(manga.id))
        bindText(statement, index: 2, value: manga.title)
        bindText(statement, index: 3, value: manga.author ?? "")
        bindText(statement, index: 4, value: manga.description ?? "")
        bindText(statement, index: 5, value: manga.coverPath ?? "")
        sqlite3_bind_int(statement, 6, Int32(manga.sourceId))
        sqlite3_bind_int(statement, 7, Int32(manga.totalChapters))

        sqlite3_step(statement)
    }

    // MARK: - Helpers

    /// Bind a text value to a prepared statement.
    private func bindText(
        _ statement: OpaquePointer?,
        index: Int32,
        value: String
    ) {
        sqlite3_bind_text(
            statement, index,
            (value as NSString).utf8String,
            -1, nil
        )
    }

    /// Read a text column from a result row.
    private func columnText(
        _ statement: OpaquePointer?,
        index: Int32
    ) -> String? {
        guard let cString = sqlite3_column_text(statement, index) else {
            return nil
        }
        return String(cString: cString)
    }
}
