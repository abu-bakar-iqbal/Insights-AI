"""
StateManager — Dual-backend system state (MongoDB + Local JSON Fallback).
"""
import os
import json
from datetime import datetime
from core.database import get_sync_db, is_mongo_available

DOCUMENT_ID = "main"
COLLECTION = "system_state"
LOCAL_STATE_FILE = "c:/Users/PMLS/Desktop/Insights AI/data/system_state.json"

_DEFAULT_STATE = {
    "_id": DOCUMENT_ID,
    "organization": "Pakistan Business Hub",
    "last_updated": str(datetime.now()),
    "metrics": {
        "monthly_revenue_pkr": "0M",
        "operating_costs_pkr": "0M",
        "compliance_score": 0,
        "overall_efficiency": 0.0,
        "efficiency_trend": [3, 4, 3.5, 5, 4.5, 6],
    },
    "active_policies": ["Standard Tax Compliance 2024"],
    "recent_actions": [],
    "web_sources": [],
    "email_recipients": [],
    "smtp_settings": {
        "host": "",
        "port": 587,
        "username": "",
        "password": "",
    },
}

class StateManager:
    def __init__(self):
        self.use_mongo = is_mongo_available()
        
        if self.use_mongo:
            self._db = get_sync_db()
            self._col = self._db[COLLECTION]
        else:
            os.makedirs(os.path.dirname(LOCAL_STATE_FILE), exist_ok=True)
            
        self._ensure_state_exists()

    def _ensure_state_exists(self):
        if self.use_mongo:
            if not self._col.find_one({"_id": DOCUMENT_ID}):
                self._col.insert_one(dict(_DEFAULT_STATE))
        else:
            if not os.path.exists(LOCAL_STATE_FILE):
                with open(LOCAL_STATE_FILE, 'w') as f:
                    # Remove _id for local JSON
                    st = dict(_DEFAULT_STATE)
                    st.pop("_id", None)
                    json.dump(st, f, indent=4)

    def get_state(self) -> dict:
        if self.use_mongo:
            doc = self._col.find_one({"_id": DOCUMENT_ID})
            if doc:
                doc.pop("_id", None)
            return doc or {}
        else:
            if os.path.exists(LOCAL_STATE_FILE):
                with open(LOCAL_STATE_FILE, 'r') as f:
                    return json.load(f)
            return {}

    def _update(self, update_fields: dict) -> dict:
        update_fields["last_updated"] = str(datetime.now())
        
        if self.use_mongo:
            self._col.update_one(
                {"_id": DOCUMENT_ID},
                {"$set": update_fields},
                upsert=True,
            )
            return self.get_state()
        else:
            state = self.get_state()
            state.update(update_fields)
            with open(LOCAL_STATE_FILE, 'w') as f:
                json.dump(state, f, indent=4)
            return state

    def update_metrics(self, new_metrics: dict) -> dict:
        current = self.get_state().get("metrics", {})
        current.update(new_metrics)
        return self._update({"metrics": current})

    def add_action_log(self, action_name: str, result) -> dict:
        entry = {
            "timestamp": str(datetime.now()),
            "action": action_name,
            "result": result,
        }
        
        if self.use_mongo:
            self._col.update_one(
                {"_id": DOCUMENT_ID},
                {"$push": {"recent_actions": entry}, "$set": {"last_updated": str(datetime.now())}},
                upsert=True,
            )
            return self.get_state()
        else:
            state = self.get_state()
            logs = state.get("recent_actions", [])
            logs.append(entry)
            return self._update({"recent_actions": logs})

    def update_efficiency_trend(self, new_value: float) -> dict:
        state = self.get_state()
        trend = state.get("metrics", {}).get("efficiency_trend", [3, 4, 3.5, 5, 4.5, 6])
        trend.append(float(new_value))
        if len(trend) > 12:
            trend = trend[-12:]
        return self.update_metrics({"efficiency_trend": trend})

    def update_smtp_settings(self, settings: dict) -> dict:
        return self._update({"smtp_settings": settings})

    def update_email_recipients(self, recipients: list) -> dict:
        return self._update({"email_recipients": recipients})

    def update_web_sources(self, sources: list) -> dict:
        return self._update({"web_sources": sources})

    def clear_action_logs(self) -> dict:
        return self._update({"recent_actions": []})
