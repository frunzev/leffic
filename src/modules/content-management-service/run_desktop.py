import os
from pathlib import Path

from desktop.desktop_server import serve_desktop

_MIGRATIONS_DIRECTORY = Path(__file__).parent / "migrations"

if __name__ == "__main__":
    serve_desktop(os.environ, _MIGRATIONS_DIRECTORY)
