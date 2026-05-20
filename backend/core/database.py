"""
MongoDB connection manager for Insights AI.
Uses Motor (async MongoDB driver) for all database operations.
Includes fallback logic so the app can run without MongoDB.
"""
import os
import urllib.parse
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import MongoClient

_async_client: AsyncIOMotorClient = None
_sync_client: MongoClient = None
_mongo_available: bool = None

DB_NAME = "insights_ai"

def get_mongo_uri() -> str:
    uri = os.getenv("MONGODB_URI", "").strip(' "\'')
    if not uri:
        return ""
    
    # Auto-escape username and password if they contain special characters
    scheme_end = uri.find("://")
    if scheme_end != -1:
        scheme_end += 3
        scheme = uri[:scheme_end]
        rest_of_uri = uri[scheme_end:]
        
        if "@" in rest_of_uri:
            credentials, cluster_info = rest_of_uri.rsplit("@", 1)
            if ":" in credentials:
                username, password = credentials.split(":", 1)
                username_quoted = urllib.parse.quote_plus(urllib.parse.unquote_plus(username))
                password_quoted = urllib.parse.quote_plus(urllib.parse.unquote_plus(password))
                uri = f"{scheme}{username_quoted}:{password_quoted}@{cluster_info}"
        
    return uri


def is_mongo_available() -> bool:
    global _mongo_available, _sync_client
    
    # If we already checked, return cached result
    if _mongo_available is not None:
        return _mongo_available
        
    uri = get_mongo_uri()
    if not uri:
        print("[DB] No MONGODB_URI found. Falling back to local storage.")
        _mongo_available = False
        return False
        
    try:
        # Attempt to ping MongoDB synchronously to confirm it works
        test_client = MongoClient(uri, serverSelectionTimeoutMS=3000)
        test_client.admin.command('ping')
        _sync_client = test_client # Keep connection alive
        _mongo_available = True
        return True
    except Exception as e:
        print(f"[DB] MongoDB connection failed: {e}")
        print("[DB] Falling back to local JSON storage.")
        _mongo_available = False
        return False


# ── Synchronous client (used by StateManager) ────────────────────────────────
def get_sync_db():
    if not is_mongo_available():
        return None
    return _sync_client[DB_NAME]


# ── Async client (used by FastAPI lifespan) ───────────────────────────────────
def get_async_client() -> AsyncIOMotorClient:
    global _async_client
    if not is_mongo_available():
        return None
        
    if _async_client is None:
        _async_client = AsyncIOMotorClient(get_mongo_uri(), serverSelectionTimeoutMS=5000)
    return _async_client


def get_async_db():
    client = get_async_client()
    if client:
        return client[DB_NAME]
    return None


def close_connections():
    global _async_client, _sync_client
    if _async_client:
        _async_client.close()
        _async_client = None
    if _sync_client:
        _sync_client.close()
        _sync_client = None
