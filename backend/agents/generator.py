from agents.base_agent import BaseAgent

class ActionGeneratorAgent(BaseAgent):
    def __init__(self):
        super().__init__("ActionGenerator", "Generates concrete, actionable recommendations.")

    async def generate_actions(self, insights_and_impact: str) -> list:
        system_prompt = """
        You are a Pragmatic Business Consultant.
        Based on the insights and impact analysis provided, suggest 3-5 REALISTIC actions.
        Each action must be:
        1. Specific (What exactly to do)
        2. Feasible (Can be done in Pakistan context)
        3. Impactful (Moves the needle)
        
        Format as JSON list with: 'id', 'title', 'steps', 'estimated_cost', 'priority'.
        """
        
        user_prompt = f"Generate recommendations based on this analysis:\n\n{insights_and_impact}"
        
        response = await self.chat(user_prompt, system_prompt)
        self.log_trace("Actions generated", None, response)
        return response
