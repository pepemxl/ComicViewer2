"""
main.py – Example usage functions for the Comic Viewer backend.

Each ``example_*`` function demonstrates a specific capability.
The ``main()`` function is called by ``__main__.py`` to showcase
all features.
"""

import uvicorn

from database import DatabaseManager


def example_database_setup() -> None:
    """
    Demonstrate database initialization and basic CRUD.

    Creates the database, adds a sample source, and prints all
    sources to verify the setup.
    """
    print("=" * 60)
    print("Example: Database Setup")
    print("=" * 60)

    db = DatabaseManager()
    print(f"Database initialized at: {db.db_path}")

    # Show existing sources
    sources = db.get_sources()
    print(f"Registered sources: {len(sources)}")
    for src in sources:
        print(f"  - [{src['id']}] {src['name']} → {src['path']}")

    print()


def example_backend_server() -> None:
    """
    Start the FastAPI backend server.

    The server runs on ``http://0.0.0.0:8000`` and serves the
    Comic Viewer REST API.  Interactive docs are available at
    ``/docs`` (Swagger UI) and ``/redoc``.
    """
    print("=" * 60)
    print("Starting Comic Viewer Backend Server")
    print("=" * 60)
    print("API docs:   http://localhost:8000/docs")
    print("ReDoc:      http://localhost:8000/redoc")
    print("Health:     http://localhost:8000/api/health")
    print("=" * 60)
    print()

    uvicorn.run(
        "api:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )


def main() -> None:
    """
    Entry point – showcase backend functionality.

    Runs the database example, then starts the server.
    """
    example_database_setup()
    example_backend_server()
