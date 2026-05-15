from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
import sys

# Ensure the backend directory is in the path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

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

@app.post("/ingest")
async def ingest_document(file: UploadFile = File(...)):
    # 1. Save File
    file_path = f"c:/Users/PMLS/Desktop/Insights AI/data/uploads/{file.filename}"
    with open(file_path, "wb") as f:
        f.write(await file.read())
    
    # 2. Run Workflow
    result = await supervisor.run_workflow(file_path)
    return result

@app.post("/simulate-action")
async def simulate_action(action_id: str, action_details: str):
    # 3. Execute Action
    result = await executor.execute_action(action_id, action_details)
    return result

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
