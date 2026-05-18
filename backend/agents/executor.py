from agents.base_agent import BaseAgent
from core.state_manager import StateManager

class ExecutorAgent(BaseAgent):
    def __init__(self, state_manager: StateManager):
        super().__init__("ExecutorAgent", "Simulates the execution of actions and updates the digital twin.")
        self.state_manager = state_manager

    async def execute_action(self, action_id: str, action_details: str) -> dict:
        self.log_trace("Execution started", {"action_id": action_id}, None)
        import os
        import json
        
        state_before = self.state_manager.get_state()
        
        system_instruction = """
        You are an Elite Agentic Simulation Engine.
        Evaluate the requested action. 
        
        If it EXPLICITLY mentions creating a public advertisement or marketing campaign:
        {
          "is_advertisement": true,
          "simulation_log": "A brief summary.",
          "ad_copy": "Engaging social media post...",
          "ad_image_prompt": "Highly descriptive prompt for image generator..."
        }
        
        If it is NOT an advertisement (e.g., workflow, operations, finance), you MUST generate a robust Action Simulation outcome.
        Provide realistic data based on the action details:
        {
          "is_advertisement": false,
          "action_taken": "The name of the action",
          "status": "SUCCESS",
          "before_state": {
            "metric_1": "1200",
            "metric_2": "2.5M PKR"
          },
          "after_state": {
            "metric_1": "projected +15%",
            "metric_2": "3.1M PKR"
          },
          "execution_logs": [
            "Step 1: Mock CRM updated",
            "Step 2: Workflow trigger initiated",
            "Step 3: Analytics dashboard updated"
          ],
          "visualization": {
            "message": "Campaign successfully launched. Expected impact: +X%",
            "metrics_changed": ["metric_1", "metric_2"]
          }
        }
        """

        prompt = f"Action to execute: {action_details}\nState: {state_before}"
        
        response_text = await self.chat(prompt, system_instruction)
        
        json_str = response_text.strip()
        if "```json" in json_str:
            json_str = json_str.split("```json")[1].split("```")[0].strip()
        elif "```" in json_str:
            json_str = json_str.split("```")[1].split("```")[0].strip()
            
        try:
            result_data = json.loads(json_str)
        except:
            result_data = {
                "is_advertisement": False,
                "action_taken": action_details[:50],
                "status": "FAILED_TO_PARSE",
                "before_state": {"status": "unknown"},
                "after_state": {"status": "unknown"},
                "execution_logs": ["System error simulating action."],
                "visualization": {"message": "Error occurred.", "metrics_changed": []}
            }
        
        # --- NEW: Tangible Action Result ---
        results_dir = "c:/Users/PMLS/Desktop/Insights AI/data/results"
        os.makedirs(results_dir, exist_ok=True)
        result_filename = f"action_result_{action_id}.txt"
        result_path = f"{results_dir}/{result_filename}"
        with open(result_path, "w") as f:
            f.write(f"ACTION EXECUTION REPORT\n=======================\n")
            f.write(f"Action ID: {action_id}\nDetails: {action_details}\n\n")
            f.write(json.dumps(result_data, indent=2))
        
        # Update the state log with meaningful name and full result for history viewing
        short_desc = action_details[:60] + "..." if len(action_details) > 60 else action_details
        
        # Filter out heavy ad copy from history to save space if needed, but keep core data
        history_data = result_data.copy()
        history_data['action_id'] = action_id
        
        self.state_manager.add_action_log(f"Simulated: {short_desc}", history_data)
        
        self.log_trace("Execution completed", None, result_data)
        
        return result_data
