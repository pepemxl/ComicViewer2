"""
api.py – FastAPI REST API for the Comic Viewer backend.

Exposes endpoints for browsing mangas, serving comic pages,
managing sources, and tracking reading progress.
"""

import mimetypes
import os
from typing import Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel

from comic_parser import get_page_count, get_page_image, get_page_thumbnail
from database import DatabaseManager
from scanner import scan_source


# ---------------------------------------------------------------------------
# Pydantic request / response models
# ---------------------------------------------------------------------------

class SourceCreate(BaseModel):
    """Schema for creating a new source."""

    name: str
    path: str
    source_type: str = "local"


class ProgressUpdate(BaseModel):
    """Schema for updating reading progress."""

    chapter_id: int
    current_page: int
    total_pages: int = 0


# ---------------------------------------------------------------------------
# App initialization
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Comic Viewer API",
    description="Backend API for browsing and reading comics / manga.",
    version="1.0.0",
)

# Allow the iOS app (and local dev) to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Shared database manager instance
db = DatabaseManager()


# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------

@app.get("/api/sources")
def list_sources():
    """Return all registered comic sources."""
    return db.get_sources()


@app.post("/api/sources", status_code=201)
def create_source(body: SourceCreate):
    """Register a new comic source directory."""
    if not os.path.isdir(body.path):
        raise HTTPException(
            status_code=400,
            detail=f"Directory does not exist: {body.path}",
        )
    source_id = db.add_source(
        name=body.name, path=body.path, source_type=body.source_type
    )
    return {"id": source_id, "message": "Source created."}


@app.post("/api/sources/{source_id}/scan")
def scan_source_endpoint(source_id: int):
    """Trigger a scan of a source directory to discover mangas."""
    source = db.get_source(source_id)
    if source is None:
        raise HTTPException(status_code=404, detail="Source not found.")
    result = scan_source(db, source_id, source["path"])
    return {
        "message": "Scan complete.",
        "mangas_found": result["mangas"],
        "chapters_found": result["chapters"],
    }


@app.delete("/api/sources/{source_id}")
def delete_source(source_id: int):
    """Delete a source and all its mangas/chapters (cascade)."""
    source = db.get_source(source_id)
    if source is None:
        raise HTTPException(status_code=404, detail="Source not found.")
    db.delete_source(source_id)
    return {"message": "Source deleted."}


# ---------------------------------------------------------------------------
# Mangas
# ---------------------------------------------------------------------------

@app.get("/api/mangas")
def list_mangas(source_id: Optional[int] = Query(None)):
    """
    Return all mangas, optionally filtered by source.

    Query parameters:
        source_id – If provided, return only mangas from that source.
    """
    if source_id is not None:
        return db.get_mangas_by_source(source_id)
    return db.get_mangas()


@app.get("/api/mangas/{manga_id}")
def get_manga(manga_id: int):
    """Return a single manga with its chapter list."""
    manga = db.get_manga(manga_id)
    if manga is None:
        raise HTTPException(status_code=404, detail="Manga not found.")
    chapters = db.get_chapters(manga_id)
    return {**manga, "chapters": chapters}


@app.delete("/api/mangas/{manga_id}")
def delete_manga(manga_id: int):
    """Delete a manga and all its chapters (cascade)."""
    manga = db.get_manga(manga_id)
    if manga is None:
        raise HTTPException(status_code=404, detail="Manga not found.")
    db.delete_manga(manga_id)
    return {"message": "Manga deleted."}


# ---------------------------------------------------------------------------
# Chapters & Pages
# ---------------------------------------------------------------------------

@app.get("/api/chapters/{chapter_id}")
def get_chapter(chapter_id: int):
    """Return chapter details including page count."""
    chapter = db.get_chapter(chapter_id)
    if chapter is None:
        raise HTTPException(status_code=404, detail="Chapter not found.")
    page_count = get_page_count(chapter["file_path"])
    return {**chapter, "page_count": page_count}


@app.get("/api/chapters/{chapter_id}/pages")
def list_pages(chapter_id: int):
    """Return metadata about all pages in a chapter."""
    chapter = db.get_chapter(chapter_id)
    if chapter is None:
        raise HTTPException(status_code=404, detail="Chapter not found.")
    page_count = get_page_count(chapter["file_path"])
    return {
        "chapter_id": chapter_id,
        "page_count": page_count,
        "pages": [
            {"page_number": i, "url": f"/api/chapters/{chapter_id}/pages/{i}"}
            for i in range(page_count)
        ],
    }


@app.get("/api/chapters/{chapter_id}/pages/{page_number}")
def get_page(chapter_id: int, page_number: int):
    """Serve a single page image from a chapter."""
    chapter = db.get_chapter(chapter_id)
    if chapter is None:
        raise HTTPException(status_code=404, detail="Chapter not found.")

    image_data = get_page_image(chapter["file_path"], page_number)
    if image_data is None:
        raise HTTPException(status_code=404, detail="Page not found.")

    # Detect content type from the first bytes
    content_type = "image/jpeg"
    if image_data[:8] == b"\x89PNG\r\n\x1a\n":
        content_type = "image/png"
    elif image_data[:4] == b"RIFF" and image_data[8:12] == b"WEBP":
        content_type = "image/webp"
    elif image_data[:3] == b"GIF":
        content_type = "image/gif"

    return Response(content=image_data, media_type=content_type)


@app.get("/api/chapters/{chapter_id}/pages/{page_number}/thumbnail")
def get_thumbnail(chapter_id: int, page_number: int):
    """Serve a thumbnail version of a page image."""
    chapter = db.get_chapter(chapter_id)
    if chapter is None:
        raise HTTPException(status_code=404, detail="Chapter not found.")

    thumb_data = get_page_thumbnail(chapter["file_path"], page_number)
    if thumb_data is None:
        raise HTTPException(status_code=404, detail="Page not found.")

    return Response(content=thumb_data, media_type="image/jpeg")


# ---------------------------------------------------------------------------
# Manga cover image
# ---------------------------------------------------------------------------

@app.get("/api/mangas/{manga_id}/cover")
def get_cover(manga_id: int):
    """Serve the cover image for a manga."""
    manga = db.get_manga(manga_id)
    if manga is None:
        raise HTTPException(status_code=404, detail="Manga not found.")

    cover_path = manga.get("cover_path", "")

    # If a cover file exists on disk, serve it
    if cover_path and os.path.isfile(cover_path):
        with open(cover_path, "rb") as f:
            data = f.read()
        mime, _ = mimetypes.guess_type(cover_path)
        return Response(content=data, media_type=mime or "image/jpeg")

    # Fallback: first page of the first chapter
    chapters = db.get_chapters(manga_id)
    if chapters:
        thumb = get_page_thumbnail(chapters[0]["file_path"], 0)
        if thumb:
            return Response(content=thumb, media_type="image/jpeg")

    raise HTTPException(status_code=404, detail="Cover not found.")


# ---------------------------------------------------------------------------
# Reading Progress
# ---------------------------------------------------------------------------

@app.get("/api/progress")
def list_progress():
    """Return all reading progress records."""
    return db.get_all_progress()


@app.get("/api/progress/{manga_id}")
def get_progress(manga_id: int):
    """Return reading progress for a specific manga."""
    progress = db.get_progress(manga_id)
    if progress is None:
        return {
            "manga_id": manga_id,
            "chapter_id": None,
            "current_page": 0,
            "total_pages": 0,
            "last_read_at": None,
        }
    return progress


@app.put("/api/progress/{manga_id}")
def update_progress(manga_id: int, body: ProgressUpdate):
    """Create or update reading progress for a manga."""
    manga = db.get_manga(manga_id)
    if manga is None:
        raise HTTPException(status_code=404, detail="Manga not found.")
    chapter = db.get_chapter(body.chapter_id)
    if chapter is None:
        raise HTTPException(status_code=404, detail="Chapter not found.")

    db.upsert_progress(
        manga_id=manga_id,
        chapter_id=body.chapter_id,
        current_page=body.current_page,
        total_pages=body.total_pages,
    )
    return {"message": "Progress updated."}


@app.delete("/api/progress/{manga_id}")
def delete_progress(manga_id: int):
    """Delete reading progress for a manga."""
    db.delete_progress(manga_id)
    return {"message": "Progress deleted."}


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/api/health")
def health_check():
    """Simple health-check endpoint."""
    return {"status": "ok", "version": app.version}
