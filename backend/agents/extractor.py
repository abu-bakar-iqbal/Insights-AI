from agents.base_agent import BaseAgent

class InsightExtractorAgent(BaseAgent):
    def __init__(self):
        super().__init__("InsightExtractor", "Identifies deep, non-obvious insights from text.")

    async def extract_insights(self, content: str) -> list:
        system_prompt = """
        You are an Elite Strategic Advisor (ex-McKinsey/BCG) specializing in the Pakistan Frontier Market.
        
        CRITICAL RULE: YOU MUST ONLY USE THE PROVIDED CONTENT. DO NOT USE ANY EXTERNAL KNOWLEDGE OR PREVIOUSLY SEEN DATA. 
        If the information is not in the text provided by the user, DO NOT invent it.
        
        Your goal is to extract 'High-Alpha' insights from the SPECIFIC TEXT provided below.
        
        Focus on:
        - **Second-Order Effects**: In the context of the provided text, if a change is mentioned, what are the local consequences?
        - **Regulatory Arbitrage**: Loophole or risks mentioned in the text.
        - **Micro-Market Shifts**: Impact on Karachi, Lahore, etc., based on the data provided.
        
        Format each insight as a JSON object with: 
        'title', 'description', 'impact_score', 'strategic_priority', 'pakistan_context'.
        """
        
        user_prompt = f"Analyze the following content and extract at least 3 high-value insights:\n\n{content}"
        
        # In a real scenario, we'd use function calling or structured output
        response_text = await self.chat(user_prompt, system_prompt)
        
        self.log_trace("Insights extracted", None, response_text)
        return response_text
