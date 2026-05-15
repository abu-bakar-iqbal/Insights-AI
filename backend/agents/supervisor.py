from agents.base_agent import BaseAgent
from agents.processor import DocumentProcessorAgent
from agents.extractor import InsightExtractorAgent
from agents.analyst import ImpactAnalystAgent
from agents.generator import ActionGeneratorAgent
from core.state_manager import StateManager
from core.logger import TraceLogger

class SupervisorAgent(BaseAgent):
    def __init__(self, state_manager: StateManager, logger: TraceLogger):
        super().__init__("Supervisor", "Orchestrates the Insight-to-Action workflow.", logger)
        self.state_manager = state_manager
        self.logger = logger
        
        # Propagate logger to sub-agents
        self.processor = DocumentProcessorAgent()
        self.processor.logger = logger
        
        self.extractor = InsightExtractorAgent()
        self.extractor.logger = logger
        
        self.analyst = ImpactAnalystAgent()
        self.analyst.logger = logger
        
        self.generator = ActionGeneratorAgent()
        self.generator.logger = logger

    async def run_workflow(self, file_path: str):
        self.logger.start_new_trace()
        self.log_trace("Workflow started", {"file": file_path}, None)

        # Step 1: Ingest
        content = await self.processor.process(file_path)

        # Step 2: Insights
        insights = await self.extractor.extract_insights(content)

        # Step 3: Impact Analysis
        current_state = self.state_manager.get_state()
        impact = await self.analyst.analyze_impact(insights, current_state)

        # Step 4: Action Generation
        actions = await self.generator.generate_actions(f"{insights}\n\nImpact Analysis:\n{impact}")

        self.log_trace("Workflow completed", None, {"insights": "Extracted and Analyzed"})
        
        return {
            "insights": insights,
            "impact_analysis": impact,
            "recommended_actions": actions,
            "trace_id": self.logger.current_trace_id
        }
