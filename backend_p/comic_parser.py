"""
comic_parser.py – Extract and serve images from comic archives and folders.

Supports CBZ (ZIP), and plain directories of images (JPG, PNG, WEBP, GIF).
"""

import os
import tempfile
import zipfile
from io import BytesIO
from typing import Optional

from PIL import Image


# Supported image extensions (lowercase, with dot)
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tiff"}


def is_image_file(filename: str) -> bool:
    """
    Check whether a filename has a recognized image extension.

    Args:
        filename: Name or path of the file.

    Returns:
        True if the extension is a supported image type.
    """
    _, ext = os.path.splitext(filename)
    return ext.lower() in IMAGE_EXTENSIONS


def is_cbz_file(filepath: str) -> bool:
    """
    Determine if a file is a CBZ (Comic Book ZIP) archive.

    Args:
        filepath: Path to the file.

    Returns:
        True if the file exists and is a valid ZIP archive.
    """
    return (
        os.path.isfile(filepath)
        and filepath.lower().endswith((".cbz", ".zip"))
        and zipfile.is_zipfile(filepath)
    )


# ---------------------------------------------------------------------------
# CBZ / ZIP extraction
# ---------------------------------------------------------------------------

def list_cbz_pages(cbz_path: str) -> list[str]:
    """
    List sorted image entries inside a CBZ/ZIP archive.

    Args:
        cbz_path: Path to the CBZ or ZIP file.

    Returns:
        Sorted list of image filenames inside the archive.
    """
    with zipfile.ZipFile(cbz_path, "r") as z:
        entries = [
            name for name in z.namelist()
            if is_image_file(name) and not name.startswith("__MACOSX")
        ]
    entries.sort()
    return entries


def extract_cbz_page(
    cbz_path: str, page_name: str
) -> Optional[bytes]:
    """
    Read a single image from a CBZ/ZIP without extracting the whole archive.

    Args:
        cbz_path:  Path to the CBZ or ZIP file.
        page_name: Name of the image entry inside the archive.

    Returns:
        Raw image bytes, or None if the entry doesn't exist.
    """
    try:
        with zipfile.ZipFile(cbz_path, "r") as z:
            return z.read(page_name)
    except (KeyError, zipfile.BadZipFile):
        return None


def extract_cbz_to_folder(
    cbz_path: str, dest_dir: Optional[str] = None
) -> str:
    """
    Extract all images from a CBZ/ZIP into a destination directory.

    Args:
        cbz_path: Path to the CBZ or ZIP file.
        dest_dir: Target directory. Defaults to a new temp directory.

    Returns:
        Path to the directory containing the extracted images.
    """
    if dest_dir is None:
        dest_dir = tempfile.mkdtemp(prefix="comicviewer_")

    with zipfile.ZipFile(cbz_path, "r") as z:
        for name in z.namelist():
            if is_image_file(name) and not name.startswith("__MACOSX"):
                z.extract(name, dest_dir)

    return dest_dir


# ---------------------------------------------------------------------------
# Folder-of-images support
# ---------------------------------------------------------------------------

def list_folder_pages(folder_path: str) -> list[str]:
    """
    List sorted image files in a directory (non-recursive).

    Args:
        folder_path: Path to the image folder.

    Returns:
        Sorted list of absolute paths to image files.
    """
    if not os.path.isdir(folder_path):
        return []

    images = [
        os.path.join(folder_path, f)
        for f in os.listdir(folder_path)
        if is_image_file(f)
    ]
    images.sort()
    return images


# ---------------------------------------------------------------------------
# Unified page access
# ---------------------------------------------------------------------------

def get_page_count(chapter_path: str) -> int:
    """
    Return the number of pages in a chapter path (CBZ or folder).

    Args:
        chapter_path: Path to a CBZ file or a folder of images.

    Returns:
        Number of image pages found.
    """
    if is_cbz_file(chapter_path):
        return len(list_cbz_pages(chapter_path))
    elif os.path.isdir(chapter_path):
        return len(list_folder_pages(chapter_path))
    return 0


def get_page_image(
    chapter_path: str, page_number: int
) -> Optional[bytes]:
    """
    Retrieve the raw image bytes for a specific page number (0-indexed).

    Works with both CBZ archives and image folders.

    Args:
        chapter_path: Path to a CBZ file or a folder of images.
        page_number:  Zero-based page index.

    Returns:
        Raw image bytes, or None if the page doesn't exist.
    """
    if is_cbz_file(chapter_path):
        pages = list_cbz_pages(chapter_path)
        if 0 <= page_number < len(pages):
            return extract_cbz_page(chapter_path, pages[page_number])

    elif os.path.isdir(chapter_path):
        pages = list_folder_pages(chapter_path)
        if 0 <= page_number < len(pages):
            with open(pages[page_number], "rb") as f:
                return f.read()

    return None


def get_page_thumbnail(
    chapter_path: str,
    page_number: int,
    max_size: tuple[int, int] = (300, 400),
) -> Optional[bytes]:
    """
    Generate a thumbnail for a specific page.

    Args:
        chapter_path: Path to a CBZ file or image folder.
        page_number:  Zero-based page index.
        max_size:     Maximum (width, height) for the thumbnail.

    Returns:
        JPEG bytes of the thumbnail, or None on failure.
    """
    image_data = get_page_image(chapter_path, page_number)
    if image_data is None:
        return None

    try:
        img = Image.open(BytesIO(image_data))
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
        buf = BytesIO()
        img.save(buf, format="JPEG", quality=85)
        return buf.getvalue()
    except Exception:
        return None
