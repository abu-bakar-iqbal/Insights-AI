import uvicorn
import os
import sys
import tempfile
from contextlib import asynccontextmanager
from dotenv import load_dotenv

# Ensure the backend directory is in the path for imports
backend_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(backend_dir)

# Explicitly load .env from the backend directory
load_dotenv(os.path.join(backend_dir, ".env"))

from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
import asyncio
from typing import List

from core.database import get_sync_db, get_async_db, close_connections
from core.state_manager import StateManager
from core.logger import TraceLogger
from agents.supervisor import SupervisorAgent
from agents.executor import ExecutorAgent
from core.mailer import Mailer

# ── Upload dir ───────────────────────────────────────────────────────────────
UPLOAD_DIR = os.path.join(backend_dir, "..", "data", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


# ── App Lifespan: connect/disconnect MongoDB ──────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("[DB] Connecting to MongoDB...")
    try:
        # Verify connection on startup
        db = get_async_db()
        await db.command("ping")
        print("[DB] MongoDB connected successfully.")
    except Exception as e:
        print(f"[DB] MongoDB connection FAILED: {e}")
        print("[DB] App will run using local fallback storage.")
    yield
    print("[DB] Closing MongoDB connections...")
    close_connections()


app = FastAPI(title="Insights AI API", lifespan=lifespan)

# Enable CORS for Flutter Web/Mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

state_manager = StateManager()
trace_logger = TraceLogger()
supervisor = SupervisorAgent(state_manager, trace_logger)
executor = ExecutorAgent(state_manager)
executor.logger = trace_logger

# ── Background Task State ─────────────────────────────────────────────────────
auto_mode_active = False
_auto_mode_task = None  # Persistent asyncio task reference


async def auto_mode_worker():
    global auto_mode_active
    print("[AutoMode] Worker started.")
    while auto_mode_active:
        try:
            state = state_manager.get_state()
            sources = state.get("web_sources", [])
            recipients = state.get("email_recipients", [])

            if sources and recipients and os.getenv("SMTP_HOST"):
                for url in sources:
                    if not auto_mode_active:
                        break
                    try:
                        content = await supervisor.processor.process_url(url)
                        result = await supervisor.run_workflow_from_content(content, f"Auto-Scrape: {url}")
                        mailer = Mailer()
                        mailer.send_report(recipients, f"Automated Insights Report - {url}", result)
                    except Exception as e:
                        print(f"[AutoMode] Error on {url}: {e}")

            # Sleep in small intervals so we can stop cleanly
            for _ in range(60):  # 60 x 10s = 10 minutes
                if not auto_mode_active:
                    break
                await asyncio.sleep(10)
        except asyncio.CancelledError:
            print("[AutoMode] Worker cancelled.")
            break
        except Exception as e:
            print(f"[AutoMode] Unexpected error: {e}")
            await asyncio.sleep(30)  # brief pause before retry
    print("[AutoMode] Worker stopped.")


# ── Core Endpoints ────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {"message": "Insights AI Backend Running", "status": "active", "db": "MongoDB"}

@app.get("/state")
async def get_current_state():
    return state_manager.get_state()

@app.get("/traces")
async def get_all_traces():
    return trace_logger.get_all_traces()

@app.post("/ingest")
async def ingest_document(files: List[UploadFile] = File(...)):
    saved_paths = []

    for file in files:
        file_path = os.path.join(UPLOAD_DIR, file.filename)
        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)
        saved_paths.append(file_path)

        # Also store file metadata in MongoDB or rely on disk
        db = get_sync_db()
        if db is not None:
            stat = os.stat(file_path)
            db["uploaded_files"].update_one(
                {"name": file.filename},
                {"$set": {
                    "name": file.filename,
                    "size_kb": round(stat.st_size / 1024, 1),
                    "date": stat.st_mtime,
                    "path": file_path,
                }},
                upsert=True,
            )

    result = await supervisor.run_workflow(saved_paths)

    # Send email if configured
    state = state_manager.get_state()
    mailer = Mailer()
    mailer.send_report(state.get("email_recipients", []), "Manual Ingest Report", result)

    return result


@app.post("/ingest-url")
async def ingest_url(url: str):
    content = await supervisor.processor.process_url(url)
    result = await supervisor.run_workflow_from_content(content, f"Web Content: {url}")

    state = state_manager.get_state()
    mailer = Mailer()
    mailer.send_report(state.get("email_recipients", []), f"URL Ingest Report - {url}", result)

    return result


class ActionRequest(BaseModel):
    action_id: str
    action_details: str


@app.post("/simulate-action")
async def simulate_action(req: ActionRequest):
    result = await executor.execute_action(req.action_id, req.action_details)

    state = state_manager.get_state()
    mailer = Mailer()
    mailer.send_report(state.get("email_recipients", []), f"Simulation Details - {req.action_id}", result)

    return {"status": "success", "result": result}


# ── File Management (MongoDB-backed metadata, disk-stored file) ───────────────

@app.get("/files")
async def get_files():
    db = get_sync_db()
    if db is not None:
        files = list(db["uploaded_files"].find({}, {"_id": 0}).sort("date", -1))
        return files
    else:
        files_list = []
        if os.path.exists(UPLOAD_DIR):
            for f in os.listdir(UPLOAD_DIR):
                file_path = os.path.join(UPLOAD_DIR, f)
                if os.path.isfile(file_path):
                    stat = os.stat(file_path)
                    files_list.append({
                        "name": f,
                        "size_kb": round(stat.st_size / 1024, 1),
                        "date": stat.st_mtime
                    })
            files_list.sort(key=lambda x: x["date"], reverse=True)
        return files_list


@app.delete("/files/{name}")
async def delete_file(name: str):
    db = get_sync_db()
    file_path = os.path.join(UPLOAD_DIR, name)

    # Remove from disk if it still exists
    file_existed = False
    if os.path.exists(file_path) and os.path.isfile(file_path):
        os.remove(file_path)
        file_existed = True

    # Remove metadata from MongoDB
    if db is not None:
        result = db["uploaded_files"].delete_one({"name": name})
        if result.deleted_count or file_existed:
            return {"status": "deleted", "file": name}
    elif file_existed:
        return {"status": "deleted", "file": name}
        
    return {"status": "not_found", "file": name}


@app.get("/files/{name}/download")
async def download_file(name: str):
    file_path = os.path.join(UPLOAD_DIR, name)
    if os.path.exists(file_path) and os.path.isfile(file_path):
        return FileResponse(file_path, filename=name)
    return {"status": "not_found"}


# ── Settings & Auto Mode Endpoints ────────────────────────────────────────────

class ListRequest(BaseModel):
    items: List[str]


@app.post("/settings/recipients")
async def set_recipients(req: ListRequest):
    state_manager.update_email_recipients(req.items)
    return {"status": "success"}


@app.post("/settings/sources")
async def set_sources(req: ListRequest):
    state_manager.update_web_sources(req.items)
    return {"status": "success"}


class AutoModeRequest(BaseModel):
    active: bool


@app.post("/settings/automode")
async def set_auto_mode(req: AutoModeRequest):
    global auto_mode_active, _auto_mode_task
    auto_mode_active = req.active
    if auto_mode_active:
        if _auto_mode_task and not _auto_mode_task.done():
            _auto_mode_task.cancel()
        _auto_mode_task = asyncio.ensure_future(auto_mode_worker())
        print("[AutoMode] Enabled — background task started.")
    else:
        if _auto_mode_task and not _auto_mode_task.done():
            _auto_mode_task.cancel()
            _auto_mode_task = None
        print("[AutoMode] Disabled.")
    return {"status": "success", "auto_mode": auto_mode_active}


@app.get("/settings/automode")
async def get_auto_mode():
    return {"auto_mode": auto_mode_active}


@app.get("/settings/config")
async def get_app_config():
    """Serve non-sensitive config values to the frontend app."""
    return {
        "pexels_api_key": os.getenv("PEXELS_API_KEY", ""),
        "organization": state_manager.get_state().get("organization", "My Organization"),
    }


# ── Analytics: Action Logs Management ────────────────────────────────────────

@app.delete("/state/logs")
async def clear_logs():
    """Clear all action logs from the state."""
    state_manager.clear_action_logs()
    return {"status": "success", "message": "Action logs cleared."}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", 8000)))
