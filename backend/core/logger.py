"""
TraceLogger — Dual-backend system for storing AI traces.
"""
import os
import json
from datetime import datetime
from typing import Any
from core.database import get_sync_db, is_mongo_available

COLLECTION = "traces"
LOCAL_DIR = "c:/Users/PMLS/Desktop/Insights AI/data/results/traces"

class TraceLogger:
    def __init__(self):
        self.use_mongo = is_mongo_available()
        if self.use_mongo:
            self._db = get_sync_db()
            self._col = self._db[COLLECTION]
        else:
            os.makedirs(LOCAL_DIR, exist_ok=True)
            
        self.current_trace_id = None
        self.steps = []

    def start_new_trace(self) -> str:
        self.current_trace_id = f"trace_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}"
        self.steps = []
        return self.current_trace_id

    def log_step(self, agent_name: str, step_name: str, input_data: Any, output_data: Any):
        entry = {
            "timestamp": str(datetime.now()),
            "agent": agent_name,
            "step": step_name,
            "input": str(input_data)[:500],
            "output": str(output_data)[:2000],
        }
        self.steps.append(entry)
        self._save()

    def _save(self):
        if not self.current_trace_id:
            return
            
        if self.use_mongo:
            self._col.update_one(
                {"trace_id": self.current_trace_id},
                {
                    "$set": {
                        "trace_id": self.current_trace_id,
                        "total_steps": len(self.steps),
                        "steps": self.steps,
                        "updated_at": str(datetime.now()),
                    }
                },
                upsert=True,
            )
        else:
            filepath = os.path.join(LOCAL_DIR, f"{self.current_trace_id}.json")
            with open(filepath, 'w') as f:
                json.dump({
                    "trace_id": self.current_trace_id,
                    "total_steps": len(self.steps),
                    "steps": self.steps
                }, f, indent=4)

    def get_all_traces(self) -> list:
        if self.use_mongo:
            traces = list(
                self._col.find(
                    {},
                    {"_id": 0},
                ).sort("trace_id", -1).limit(100)
            )
            return traces
        else:
            traces = []
            if os.path.exists(LOCAL_DIR):
                for file in os.listdir(LOCAL_DIR):
                    if file.endswith(".json"):
                        with open(os.path.join(LOCAL_DIR, file), 'r') as f:
                            traces.append(json.load(f))
            return sorted(traces, key=lambda x: x.get('trace_id', ''), reverse=True)
