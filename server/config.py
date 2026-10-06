import json
import os
from pathlib import Path
from typing import List, Optional
from pydantic import BaseModel

BASE_DIR = Path(__file__).resolve().parent
CONFIG_PATH = BASE_DIR / "config.json"


class ServerSettings(BaseModel):
    app_name: str = "ENX Money REST API Server"
    version: str = "1.0.0"
    host: str = "127.0.0.1"
    port: int = 8000
    debug: bool = True
    cors_origins: List[str] = ["*"]
    storage_file: str = "data/data.json"
    exports_directory: str = "exports"
    default_currency: str = "INR"
    currency_symbol: str = "₹"

    @property
    def storage_path(self) -> Path:
        return BASE_DIR / self.storage_file

    @property
    def exports_path(self) -> Path:
        return BASE_DIR / self.exports_directory


def load_settings() -> ServerSettings:
    if CONFIG_PATH.exists():
        try:
            with open(CONFIG_PATH, "r", encoding="utf-8") as f:
                data = json.load(f)
                return ServerSettings(**data)
        except Exception as e:
            print(f"[WARN] Failed to read config.json, using defaults: {e}")
    return ServerSettings()


settings = load_settings()
