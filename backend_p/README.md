# Comic Viewer – Python Backend

REST API backend for the Comic Viewer application. Serves comic pages from
CBZ/ZIP archives and image folders, manages a SQLite library database, and
tracks reading progress.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run the server
python __main__.py
```

The server starts at **http://localhost:8000**.

- Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs)
- ReDoc: [http://localhost:8000/redoc](http://localhost:8000/redoc)

## API Endpoints

| Method   | Endpoint                                    | Description              |
|----------|---------------------------------------------|--------------------------|
| `GET`    | `/api/health`                               | Health check             |
| `GET`    | `/api/mangas`                               | List all mangas          |
| `GET`    | `/api/mangas/{id}`                          | Manga detail + chapters  |
| `GET`    | `/api/mangas/{id}/cover`                    | Manga cover image        |
| `GET`    | `/api/chapters/{id}`                        | Chapter detail           |
| `GET`    | `/api/chapters/{id}/pages`                  | List pages in chapter    |
| `GET`    | `/api/chapters/{id}/pages/{page}`           | Serve page image         |
| `GET`    | `/api/chapters/{id}/pages/{page}/thumbnail` | Page thumbnail           |
| `GET`    | `/api/progress`                             | All reading progress     |
| `GET`    | `/api/progress/{manga_id}`                  | Progress for a manga     |
| `PUT`    | `/api/progress/{manga_id}`                  | Update reading progress  |
| `POST`   | `/api/sources`                              | Add a source directory   |
| `POST`   | `/api/sources/{id}/scan`                    | Scan source for comics   |
| `DELETE` | `/api/sources/{id}`                         | Delete a source          |

## Architecture

- **`api.py`** – FastAPI REST API
- **`database.py`** – SQLite schema and CRUD operations
- **`comic_parser.py`** – CBZ/ZIP and image folder parsing
- **`scanner.py`** – Filesystem scanner for discovering comics
- **`main.py`** – Example usage / server startup
- **`__main__.py`** – Package entry point
