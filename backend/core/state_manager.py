import json
import os
from datetime import datetime

class StateManager:
    def __init__(self, state_file="c:/Users/PMLS/Desktop/Insights AI/data/system_state.json"):
        self.state_file = state_file
        self.ensure_state_exists()

    def ensure_state_exists(self):
        if not os.path.exists(self.state_file):
            initial_state = {
                "organization": "Pakistan Business Hub",
                "last_updated": str(datetime.now()),
                "metrics": {
                    "monthly_revenue_pkr": 5000000,
                    "operating_costs_pkr": 3000000,
                    "compliance_score": 85
                },
                "active_policies": ["Standard Tax Compliance 2024"],
                "recent_actions": []
            }
            self.save_state(initial_state)

    def get_state(self):
        with open(self.state_file, 'r') as f:
            return json.load(f)

    def save_state(self, state):
        state["last_updated"] = str(datetime.now())
        with open(self.state_file, 'w') as f:
            json.dump(state, f, indent=4)
        return state

    def update_metrics(self, new_metrics):
        state = self.get_state()
        state["metrics"].update(new_metrics)
        return self.save_state(state)

    def add_action_log(self, action_name, result):
        state = self.get_state()
        state["recent_actions"].append({
            "timestamp": str(datetime.now()),
            "action": action_name,
            "result": result
        })
        return self.save_state(state)
