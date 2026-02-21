"""
scanner.py – Filesystem scanner for discovering comics and manga.

Walks a source directory tree to identify manga folders and chapters
(CBZ files or image-filled subdirectories), then registers them in
the database.
"""

import os
import re
from typing import Optional

from comic_parser import (
    IMAGE_EXTENSIONS,
    get_page_count,
    is_cbz_file,
    is_image_file,
)
from database import DatabaseManager


def _extract_chapter_number(name: str) -> float:
    """
    Attempt to extract a chapter number from a filename or folder name.

    Tries patterns like "Chapter 05", "Ch.12", "c003", or just a leading
    number.  Falls back to 0.0 if nothing recognizable is found.

    Args:
        name: Filename or directory name (without path).

    Returns:
        Extracted chapter number as a float.
    """
    # Try "Chapter 12.5", "Ch.005", "c03" patterns
    match = re.search(r"(?:ch(?:apter)?[\s._-]*)(\d+(?:\.\d+)?)", name, re.I)
    if match:
        return float(match.group(1))

    # Try leading numeric portion (e.g., "001 - Title")
    match = re.match(r"(\d+(?:\.\d+)?)", name)
    if match:
        return float(match.group(1))

    return 0.0


def _find_cover(path: str) -> Optional[str]:
    """
    Find the best cover image in a directory.

    Looks for files named 'cover', 'folder', or 'poster', then falls
    back to the first image file found.

    Args:
        path: Directory to search.

    Returns:
        Absolute path to the cover image, or None.
    """
    if not os.path.isdir(path):
        return None

    files = sorted(os.listdir(path))
    cover_names = {"cover", "folder", "poster", "thumb", "thumbnail"}

    # Priority: explicitly-named cover files
    for f in files:
        stem, ext = os.path.splitext(f)
        if stem.lower() in cover_names and ext.lower() in IMAGE_EXTENSIONS:
            return os.path.join(path, f)

    # Fallback: first image file
    for f in files:
        if is_image_file(f):
            return os.path.join(path, f)

    return None


def scan_source(
    db: DatabaseManager,
    source_id: int,
    source_path: str,
) -> dict:
    """
    Scan a source directory to discover mangas and chapters.

    Expected directory layout::

        source_path/
        ├── Manga Title A/
        │   ├── Chapter 01.cbz
        │   ├── Chapter 02.cbz
        │   └── cover.jpg
        └── Manga Title B/
            ├── 001/
            │   ├── page_001.jpg
            │   └── page_002.jpg
            └── 002/
                ├── page_001.jpg
                └── page_002.jpg

    Each immediate subdirectory of *source_path* is treated as a manga.
    Within each manga directory, CBZ files and image-containing
    subdirectories are treated as chapters.

    Args:
        db:          DatabaseManager instance.
        source_id:   ID of the source record in the DB.
        source_path: Absolute path to the source directory.

    Returns:
        Summary dict with counts: ``{"mangas": int, "chapters": int}``.
    """
    if not os.path.isdir(source_path):
        return {"mangas": 0, "chapters": 0}

    manga_count = 0
    chapter_count = 0

    # Each immediate child directory = one manga
    for manga_name in sorted(os.listdir(source_path)):
        manga_dir = os.path.join(source_path, manga_name)
        if not os.path.isdir(manga_dir):
            continue

        # Discover chapters inside this manga folder
        chapters_found: list[dict] = []

        for entry in sorted(os.listdir(manga_dir)):
            entry_path = os.path.join(manga_dir, entry)

            # CBZ / ZIP files → chapter
            if is_cbz_file(entry_path):
                chapters_found.append({
                    "number": _extract_chapter_number(entry),
                    "title": os.path.splitext(entry)[0],
                    "path": entry_path,
                    "page_count": get_page_count(entry_path),
                })

            # Subdirectory with images → chapter
            elif os.path.isdir(entry_path):
                page_cnt = get_page_count(entry_path)
                if page_cnt > 0:
                    chapters_found.append({
                        "number": _extract_chapter_number(entry),
                        "title": entry,
                        "path": entry_path,
                        "page_count": page_cnt,
                    })

        # Skip directories with no discoverable chapters
        if not chapters_found:
            continue

        # Find a cover image
        cover = _find_cover(manga_dir)

        # Register manga in the database
        manga_id = db.add_manga(
            title=manga_name,
            source_id=source_id,
            cover_path=cover or "",
            total_chapters=len(chapters_found),
        )
        manga_count += 1

        # Register each chapter
        for ch in chapters_found:
            db.add_chapter(
                manga_id=manga_id,
                chapter_number=ch["number"],
                file_path=ch["path"],
                title=ch["title"],
                page_count=ch["page_count"],
            )
            chapter_count += 1

    return {"mangas": manga_count, "chapters": chapter_count}
