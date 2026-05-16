from agents.base_agent import BaseAgent

class ImpactAnalystAgent(BaseAgent):
    def __init__(self):
        super().__init__("ImpactAnalyst", "Analyzes the quantitative and qualitative impact of insights.")

    async def analyze_impact(self, insight: str, context: dict) -> str:
        system_prompt = f"""
        You are a Financial Risk and Impact Analyst.
        Current System State Context: {context}
        
        CRITICAL RULE: DO NOT INVENT FINANCIAL DATA. Only use the numbers provided in the 'Current System State Context' and the 'Insight' text.
        
        Analyze the impact of the following insight on the organization.
        Quantify impact in PKR using the provided context metrics.
        Determine if this is a 'Risk' or an 'Opportunity'.
        """
        
        user_prompt = f"Perform an impact analysis for this insight: {insight}"
        
        response = await self.chat(user_prompt, system_prompt)
        self.log_trace("Impact analysis completed", {"insight": insight}, response)
        return response
