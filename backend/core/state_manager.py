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
                    "monthly_revenue_pkr": "0M",
                    "operating_costs_pkr": "0M",
                    "compliance_score": 0,
                    "efficiency_trend": [3, 4, 3.5, 5, 4.5, 6]
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

    def update_efficiency_trend(self, new_value):
        state = self.get_state()
        trend = state["metrics"].get("efficiency_trend", [3, 4, 3.5, 5, 4.5, 6])
        trend.append(float(new_value))
        if len(trend) > 6:
            trend = trend[-6:] # Keep only the last 6 points for the chart
        state["metrics"]["efficiency_trend"] = trend
        return self.save_state(state)
