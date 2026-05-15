from agents.base_agent import BaseAgent
from core.state_manager import StateManager

class ExecutorAgent(BaseAgent):
    def __init__(self, state_manager: StateManager):
        super().__init__("ExecutorAgent", "Simulates the execution of actions and updates the digital twin.")
        self.state_manager = state_manager

    async def execute_action(self, action_id: str, action_details: str) -> dict:
        self.log_trace("Execution started", {"action_id": action_id}, None)
        
        state_before = self.state_manager.get_state()
        
        prompt = f"""
        Current State: {state_before}
        Action to execute: {action_details}
        
        Simulate the outcome of this action. What specific metrics in the state would change? 
        Provide the updated state values in JSON format.
        Also, write a 2-paragraph 'Strategic Implementation Plan' for this action.
        """
        
        simulation_result = await self.chat(prompt, "You are a System Simulator and Strategic Consultant.")
        
        # --- NEW: Tangible Action Result ---
        result_filename = f"action_result_{action_id}.txt"
        result_path = f"c:/Users/PMLS/Desktop/Insights AI/data/results/{result_filename}"
        with open(result_path, "w") as f:
            f.write(f"ACTION EXECUTION REPORT\n")
            f.write(f"=======================\n")
            f.write(f"Action ID: {action_id}\n")
            f.write(f"Details: {action_details}\n\n")
            f.write(f"SIMULATION OUTPUT:\n{simulation_result}")
        
        # Update the state log
        self.state_manager.add_action_log(action_id, f"Report generated at {result_filename}")
        
        state_after = self.state_manager.get_state()
        self.log_trace("Execution completed", None, {"file_generated": result_filename})
        
        return {
            "before": state_before,
            "after": state_after,
            "simulation_log": simulation_result,
            "artifact_path": result_path
        }
