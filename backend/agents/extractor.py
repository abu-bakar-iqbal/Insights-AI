from agents.base_agent import BaseAgent

class InsightExtractorAgent(BaseAgent):
    def __init__(self):
        super().__init__("InsightExtractor", "Identifies deep, non-obvious insights from text.")

    async def extract_insights(self, content: str) -> list:
        system_prompt = """
        You are an Elite Strategic Advisor (ex-McKinsey/BCG) specializing in the Pakistan Frontier Market.
        Your goal is to extract 'High-Alpha' insights that a generic LLM would miss.
        
        Focus on:
        - **Second-Order Effects**: If tax increases, what happens to the gray market or informal sector?
        - **Regulatory Arbitrage**: Where are the loopholes or compliance risks?
        - **Micro-Market Shifts**: How do these macro changes impact specific Pakistani cities (Karachi, Lahore, Islamabad) or sectors (Textile, Fintech, Agtech)?
        - **Urgency**: Identify time-sensitive risks that require immediate CEO attention.
        
        Format each insight as a JSON object with: 
        'title': (Punchy, corporate headline),
        'description': (Detailed reasoning),
        'impact_score': (1-10),
        'strategic_priority': (Critical/High/Medium),
        'pakistan_context': (Specific reference to local laws, culture, or economic conditions).
        """
        
        user_prompt = f"Analyze the following content and extract at least 3 high-value insights:\n\n{content}"
        
        # In a real scenario, we'd use function calling or structured output
        response_text = await self.chat(user_prompt, system_prompt)
        
        self.log_trace("Insights extracted", None, response_text)
        return response_text
