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
          "simulation_log": "A very short, summarized 1-sentence explanation.",
          "ad_copy": "Short engaging social media post...",
          "ad_image_prompt": "tax, finance, business" // MUST be exactly 2-3 single words separated by commas, directly related to tax, finance, or business matching the campaign. Do not write full sentences.
        }
        
        If it is NOT an advertisement (e.g., workflow, operations, finance), you MUST generate a robust Action Simulation outcome.
        Keep all descriptions extremely short, simple, and summarized so a layman can understand.
        Provide realistic data based on the action details.
        CRITICAL RULE: Any monetary value or large numerical figure MUST be formatted using M (Millions) or B (Billions) suffix (e.g., "3.1M" or "2.5B" instead of raw digits like "3,100,000" or "2,500,000,000").
        
        Provide output matching:
        {
          "is_advertisement": false,
          "action_taken": "The name of the action (simple & clean)",
          "status": "SUCCESS",
          "before_state": {
            "metric_1": "1200",
            "metric_2": "2.5M"
          },
          "after_state": {
            "metric_1": "projected +15%",
            "metric_2": "3.1M"
          },
          "execution_logs": [
            "Step 1: Short action step (max 8 words)",
            "Step 2: Short action step (max 8 words)",
            "Step 3: Short action step (max 8 words)"
          ],
          "visualization": {
            "message": "Extremely short summary of the impact. Max 12 words.",
            "metrics_changed": ["metric_1", "metric_2"]
          }
        }
        """

        prompt = f"Action to execute: {action_details}\nState: {state_before}"
        
        try:
            response_text = await self.chat(prompt, system_instruction)
            json_str = response_text.strip()
            if "```json" in json_str:
                json_str = json_str.split("```json")[1].split("```")[0].strip()
            elif "```" in json_str:
                json_str = json_str.split("```")[1].split("```")[0].strip()
        except Exception as e:
            self.log_trace("Gemini API Error", None, {"error": str(e)})
            json_str = '{"is_advertisement": false, "action_taken": "API Error", "status": "FAILED", "before_state": {}, "after_state": {}, "execution_logs": ["Gemini API Blocked", "Please fix your API key."], "visualization": {"message": "API Error. Check backend terminal.", "metrics_changed": []}}'
            
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
        
        # Sync simulated after_state back to active metrics
        if not result_data.get("is_advertisement", False) and "after_state" in result_data:
            after = result_data["after_state"]
            new_metrics = {}
            
            # Helper to check key variations
            def get_val(keys):
                for k in keys:
                    if k in after:
                        return after[k]
                return None
                
            rev = get_val(["monthly_revenue_pkr", "monthly_revenue", "revenue"])
            if rev:
                new_metrics["monthly_revenue_pkr"] = str(rev)
                
            costs = get_val(["operating_costs_pkr", "operating_costs", "costs", "manual_processing_cost_pkr_per_month"])
            if costs:
                new_metrics["operating_costs_pkr"] = str(costs)
                
            comp = get_val(["compliance_score", "compliance_rate", "compliance"])
            if comp:
                comp_clean = str(comp).replace("%", "").replace("projected", "").replace("+", "").replace("-", "").strip()
                try:
                    comp_clean = comp_clean.split()[0]
                    new_metrics["compliance_score"] = float(comp_clean)
                except:
                    new_metrics["compliance_score"] = comp
                    
            if new_metrics:
                self.state_manager.update_metrics(new_metrics)
        
        self.log_trace("Execution completed", None, result_data)
        
        return result_data
