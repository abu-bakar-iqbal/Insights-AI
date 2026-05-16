import uvicorn
import os
import sys
from dotenv import load_dotenv

# Ensure the backend directory is in the path for imports
backend_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(backend_dir)

# Explicitly load .env from the backend directory
load_dotenv(os.path.join(backend_dir, ".env"))

from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from core.state_manager import StateManager
from core.logger import TraceLogger
from agents.supervisor import SupervisorAgent
from agents.executor import ExecutorAgent

app = FastAPI(title="Insights AI API")

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

@app.get("/")
async def root():
    return {"message": "Insights AI Backend Running", "status": "active"}

@app.get("/state")
async def get_current_state():
    return state_manager.get_state()

@app.get("/traces")
async def get_all_traces():
    return trace_logger.get_all_traces()

from typing import List

@app.post("/ingest")
async def ingest_document(files: List[UploadFile] = File(...)):
    # 1. Save Files
    saved_paths = []
    upload_dir = "c:/Users/PMLS/Desktop/Insights AI/data/uploads"
    os.makedirs(upload_dir, exist_ok=True)
    
    for file in files:
        file_path = f"{upload_dir}/{file.filename}"
        with open(file_path, "wb") as f:
            f.write(await file.read())
        saved_paths.append(file_path)
    
    # 2. Run Workflow on all files
    result = await supervisor.run_workflow(saved_paths)
    return result

@app.post("/ingest-url")
async def ingest_url(url: str):
    # 1. Process URL content
    content = await supervisor.processor.process_url(url)
    
    # 2. Run Workflow on scraped content
    result = await supervisor.run_workflow_from_content(content, f"Web Content: {url}")
    return result

from pydantic import BaseModel
class ActionRequest(BaseModel):
    action_id: str
    action_details: str

@app.post("/simulate-action")
async def simulate_action(req: ActionRequest):
    # Run the executor agent
    result = await executor.execute_action(req.action_id, req.action_details)
    return {"status": "success", "result": result}

@app.get("/files")
async def get_files():
    upload_dir = "c:/Users/PMLS/Desktop/Insights AI/data/uploads"
    if not os.path.exists(upload_dir):
        return []
    
    files_list = []
    for f in os.listdir(upload_dir):
        file_path = os.path.join(upload_dir, f)
        if os.path.isfile(file_path):
            stat = os.stat(file_path)
            files_list.append({
                "name": f,
                "size_kb": round(stat.st_size / 1024, 1),
                "date": stat.st_mtime
            })
    
    # Sort by date descending
    files_list.sort(key=lambda x: x["date"], reverse=True)
    return files_list

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
