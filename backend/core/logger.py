import json
import os
from datetime import datetime
from typing import Any, Dict

class TraceLogger:
    def __init__(self, log_dir="c:/Users/PMLS/Desktop/Insights AI/data/results/traces"):
        self.log_dir = log_dir
        os.makedirs(self.log_dir, exist_ok=True)
        self.current_trace_id = None
        self.steps = []

    def start_new_trace(self):
        self.current_trace_id = f"trace_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.steps = []
        return self.current_trace_id

    def log_step(self, agent_name: str, step_name: str, input_data: Any, output_data: Any):
        entry = {
            "timestamp": str(datetime.now()),
            "agent": agent_name,
            "step": step_name,
            "input": str(input_data)[:500], # Truncate for log size
            "output": str(output_data)[:2000]
        }
        self.steps.append(entry)
        self._save()

    def _save(self):
        if not self.current_trace_id:
            return
        
        filepath = os.path.join(self.log_dir, f"{self.current_trace_id}.json")
        with open(filepath, 'w') as f:
            json.dump({
                "trace_id": self.current_trace_id,
                "total_steps": len(self.steps),
                "steps": self.steps
            }, f, indent=4)

    def get_all_traces(self):
        traces = []
        for file in os.listdir(self.log_dir):
            if file.endswith(".json"):
                with open(os.path.join(self.log_dir, file), 'r') as f:
                    traces.append(json.load(f))
        return sorted(traces, key=lambda x: x['trace_id'], reverse=True)
