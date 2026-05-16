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
        You are an Elite Marketing and Execution Simulator.
        You must evaluate the requested action. If it involves advertising, marketing, social media, or public relations, flag it as an advertisement.
        
        OUTPUT MUST BE VALID JSON:
        {
          "is_advertisement": true/false,
          "simulation_log": "A brief 2-sentence summary of the action execution.",
          "ad_copy": "If true, write an engaging social media post (with emojis and hashtags). If false, leave empty.",
          "ad_image_prompt": "If true, write a highly descriptive prompt for an AI image generator to create a professional ADVERTISEMENT BANNER. Explicitly ask for bold typography, marketing elements, vibrant colors, and clear visual messaging (e.g., 'A professional advertisement banner with bold typography saying Special Offer, featuring a sleek modern laptop on a vibrant glowing background, marketing poster style'). If false, leave empty."
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
                "simulation_log": "Simulated execution completed.",
                "ad_copy": "",
                "ad_image_prompt": ""
            }
        
        # --- NEW: Tangible Action Result ---
        results_dir = "c:/Users/PMLS/Desktop/Insights AI/data/results"
        os.makedirs(results_dir, exist_ok=True)
        result_filename = f"action_result_{action_id}.txt"
        result_path = f"{results_dir}/{result_filename}"
        with open(result_path, "w") as f:
            f.write(f"ACTION EXECUTION REPORT\n=======================\n")
            f.write(f"Action ID: {action_id}\nDetails: {action_details}\n\n")
            f.write(f"SIMULATION OUTPUT:\n{result_data['simulation_log']}\n")
        
        # Update the state log
        self.state_manager.add_action_log(f"Executed: {action_id}", f"Report generated")
        
        self.log_trace("Execution completed", None, result_data)
        
        return {
            "action_id": action_id,
            "simulation_log": result_data["simulation_log"],
            "is_advertisement": result_data.get("is_advertisement", False),
            "ad_copy": result_data.get("ad_copy", ""),
            "ad_image_prompt": result_data.get("ad_image_prompt", "")
        }
