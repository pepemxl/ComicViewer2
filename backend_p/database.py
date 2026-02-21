"""
database.py – SQLite database manager for the Comic Viewer backend.

Handles schema creation, connection management, and CRUD operations
for sources, mangas, chapters, pages, and reading progress.
"""

import os
import sqlite3
from datetime import datetime
from typing import Any, Optional


# Default database path (relative to backend_p/)
DEFAULT_DB_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "comicviewer.db"
)


# ---------------------------------------------------------------------------
# Schema Definitions
# ---------------------------------------------------------------------------

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS sources (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    path        TEXT    NOT NULL UNIQUE,
    source_type TEXT    NOT NULL DEFAULT 'local',
    created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS mangas (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    title           TEXT    NOT NULL,
    author          TEXT,
    description     TEXT,
    cover_path      TEXT,
    source_id       INTEGER NOT NULL,
    total_chapters  INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS chapters (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    manga_id        INTEGER NOT NULL,
    chapter_number  REAL    NOT NULL,
    title           TEXT,
    file_path       TEXT    NOT NULL,
    page_count      INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (manga_id) REFERENCES mangas(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS pages (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    chapter_id      INTEGER NOT NULL,
    page_number     INTEGER NOT NULL,
    file_path       TEXT    NOT NULL,
    FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reading_progress (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    manga_id        INTEGER NOT NULL UNIQUE,
    chapter_id      INTEGER NOT NULL,
    current_page    INTEGER NOT NULL DEFAULT 0,
    total_pages     INTEGER NOT NULL DEFAULT 0,
    last_read_at    TEXT    NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (manga_id)  REFERENCES mangas(id)   ON DELETE CASCADE,
    FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
);
"""


# ---------------------------------------------------------------------------
# Database Manager
# ---------------------------------------------------------------------------

class DatabaseManager:
    """Manages SQLite connections and provides CRUD helpers."""

    def __init__(self, db_path: str = DEFAULT_DB_PATH) -> None:
        """
        Initialize the database manager.

        Args:
            db_path: Path to the SQLite database file.
        """
        self.db_path = db_path
        self._init_db()

    # -- Connection helpers --------------------------------------------------

    def _get_connection(self) -> sqlite3.Connection:
        """Create and return a new database connection."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        return conn

    def _init_db(self) -> None:
        """Create tables if they don't exist."""
        with self._get_connection() as conn:
            conn.executescript(SCHEMA_SQL)

    # -- Generic helpers -----------------------------------------------------

    def _fetchall(self, query: str, params: tuple = ()) -> list[dict]:
        """Execute a SELECT and return all rows as dicts."""
        with self._get_connection() as conn:
            rows = conn.execute(query, params).fetchall()
            return [dict(row) for row in rows]

    def _fetchone(
        self, query: str, params: tuple = ()
    ) -> Optional[dict]:
        """Execute a SELECT and return a single row as dict or None."""
        with self._get_connection() as conn:
            row = conn.execute(query, params).fetchone()
            return dict(row) if row else None

    def _execute(
        self, query: str, params: tuple = ()
    ) -> int:
        """Execute an INSERT/UPDATE/DELETE and return lastrowid."""
        with self._get_connection() as conn:
            cursor = conn.execute(query, params)
            conn.commit()
            return cursor.lastrowid

    # -----------------------------------------------------------------------
    # Sources
    # -----------------------------------------------------------------------

    def add_source(
        self, name: str, path: str, source_type: str = "local"
    ) -> int:
        """
        Register a new comic source directory.

        Args:
            name:        Human-readable label for the source.
            path:        Absolute filesystem path to the source directory.
            source_type: Type of source (default ``"local"``).

        Returns:
            The new source row ID.
        """
        return self._execute(
            "INSERT INTO sources (name, path, source_type) VALUES (?, ?, ?)",
            (name, path, source_type),
        )

    def get_sources(self) -> list[dict]:
        """Return all registered sources."""
        return self._fetchall("SELECT * FROM sources ORDER BY name")

    def get_source(self, source_id: int) -> Optional[dict]:
        """Return a single source by ID."""
        return self._fetchone("SELECT * FROM sources WHERE id = ?", (source_id,))

    def delete_source(self, source_id: int) -> None:
        """Delete a source and all associated data (cascade)."""
        self._execute("DELETE FROM sources WHERE id = ?", (source_id,))

    # -----------------------------------------------------------------------
    # Mangas
    # -----------------------------------------------------------------------

    def add_manga(
        self,
        title: str,
        source_id: int,
        author: str = "",
        description: str = "",
        cover_path: str = "",
        total_chapters: int = 0,
    ) -> int:
        """
        Insert a new manga record.

        Returns:
            The new manga row ID.
        """
        return self._execute(
            """INSERT INTO mangas
               (title, author, description, cover_path, source_id, total_chapters)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (title, author, description, cover_path, source_id, total_chapters),
        )

    def get_mangas(self) -> list[dict]:
        """Return all mangas ordered by title."""
        return self._fetchall("SELECT * FROM mangas ORDER BY title")

    def get_manga(self, manga_id: int) -> Optional[dict]:
        """Return a single manga by ID."""
        return self._fetchone("SELECT * FROM mangas WHERE id = ?", (manga_id,))

    def get_mangas_by_source(self, source_id: int) -> list[dict]:
        """Return mangas belonging to a specific source."""
        return self._fetchall(
            "SELECT * FROM mangas WHERE source_id = ? ORDER BY title",
            (source_id,),
        )

    def update_manga(self, manga_id: int, **fields: Any) -> None:
        """
        Update manga fields dynamically.

        Args:
            manga_id: Target manga ID.
            **fields: Column=value pairs to update.
        """
        if not fields:
            return
        set_clause = ", ".join(f"{k} = ?" for k in fields)
        values = list(fields.values()) + [manga_id]
        self._execute(
            f"UPDATE mangas SET {set_clause}, updated_at = datetime('now') "
            f"WHERE id = ?",
            tuple(values),
        )

    def delete_manga(self, manga_id: int) -> None:
        """Delete a manga and all associated data (cascade)."""
        self._execute("DELETE FROM mangas WHERE id = ?", (manga_id,))

    # -----------------------------------------------------------------------
    # Chapters
    # -----------------------------------------------------------------------

    def add_chapter(
        self,
        manga_id: int,
        chapter_number: float,
        file_path: str,
        title: str = "",
        page_count: int = 0,
    ) -> int:
        """
        Insert a new chapter.

        Returns:
            The new chapter row ID.
        """
        return self._execute(
            """INSERT INTO chapters
               (manga_id, chapter_number, title, file_path, page_count)
               VALUES (?, ?, ?, ?, ?)""",
            (manga_id, chapter_number, title, file_path, page_count),
        )

    def get_chapters(self, manga_id: int) -> list[dict]:
        """Return all chapters for a manga, ordered by number."""
        return self._fetchall(
            "SELECT * FROM chapters WHERE manga_id = ? ORDER BY chapter_number",
            (manga_id,),
        )

    def get_chapter(self, chapter_id: int) -> Optional[dict]:
        """Return a single chapter by ID."""
        return self._fetchone(
            "SELECT * FROM chapters WHERE id = ?", (chapter_id,)
        )

    # -----------------------------------------------------------------------
    # Pages
    # -----------------------------------------------------------------------

    def add_page(
        self, chapter_id: int, page_number: int, file_path: str
    ) -> int:
        """
        Insert a page record.

        Returns:
            The new page row ID.
        """
        return self._execute(
            "INSERT INTO pages (chapter_id, page_number, file_path) "
            "VALUES (?, ?, ?)",
            (chapter_id, page_number, file_path),
        )

    def get_pages(self, chapter_id: int) -> list[dict]:
        """Return all pages for a chapter, ordered by page number."""
        return self._fetchall(
            "SELECT * FROM pages WHERE chapter_id = ? ORDER BY page_number",
            (chapter_id,),
        )

    # -----------------------------------------------------------------------
    # Reading Progress
    # -----------------------------------------------------------------------

    def upsert_progress(
        self,
        manga_id: int,
        chapter_id: int,
        current_page: int,
        total_pages: int = 0,
    ) -> int:
        """
        Create or update reading progress for a manga.

        Uses SQLite ``ON CONFLICT`` to upsert by ``manga_id``.

        Returns:
            The progress row ID.
        """
        return self._execute(
            """INSERT INTO reading_progress
               (manga_id, chapter_id, current_page, total_pages, last_read_at)
               VALUES (?, ?, ?, ?, datetime('now'))
               ON CONFLICT(manga_id) DO UPDATE SET
                   chapter_id   = excluded.chapter_id,
                   current_page = excluded.current_page,
                   total_pages  = excluded.total_pages,
                   last_read_at = datetime('now')
            """,
            (manga_id, chapter_id, current_page, total_pages),
        )

    def get_progress(self, manga_id: int) -> Optional[dict]:
        """Return reading progress for a manga."""
        return self._fetchone(
            "SELECT * FROM reading_progress WHERE manga_id = ?",
            (manga_id,),
        )

    def get_all_progress(self) -> list[dict]:
        """Return all reading progress records."""
        return self._fetchall(
            "SELECT * FROM reading_progress ORDER BY last_read_at DESC"
        )

    def delete_progress(self, manga_id: int) -> None:
        """Delete reading progress for a manga."""
        self._execute(
            "DELETE FROM reading_progress WHERE manga_id = ?",
            (manga_id,),
        )
