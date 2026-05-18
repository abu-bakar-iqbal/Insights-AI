import json
from agents.processor import DocumentProcessorAgent

SYSTEM_PROMPT = """
You are an Elite Strategic Advisor specializing in the Pakistan market.

CRITICAL RULE 1: Only use information from the provided document text. Do NOT invent facts.
CRITICAL RULE 2: EXTREME BREVITY. Assume the CEO has exactly 10 seconds to read the entire report. Use ONLY point-to-point data. No fluff, no detailed paragraphs. Maximum 15 words for any description or content field.
CRITICAL RULE 3: EXTRACT REAL PRICES. You must extract exact numerical monetary values (PKR, USD, prices, costs) directly from the text. NEVER use placeholders like 'X,XXX'. If exact numbers aren't found, make a highly educated data-driven estimate based on the text.
CRITICAL RULE 4: FIRST ACTION IS ALWAYS MARKETING. The very first execution plan (id: "A1") MUST always be a public advertising, social media, or marketing campaign designed to reduce the biggest risk or promote the biggest opportunity found in the data.

Analyze the provided content and generate a CEO-level strategic intelligence report.
Your output MUST be valid JSON in exactly this format (no extra text outside the JSON):

{
  "extracted_metrics": {
    "monthly_revenue_pkr": "...", // Extract real monetary value (e.g. "PKR 5.2M")
    "operating_costs_pkr": "...", // Extract real cost (e.g. "PKR 1.1M")
    "compliance_score": 0, // e.g. 85 or 0 if not found
    "overall_efficiency": 0.0 // A score from 1.0 to 10.0 based on the document's tone
  },
  "main_feeds": [
    {"title": "...", "content": "..."}
  ],
  "risks": [
    {
      "title": "...",
      "severity": "High",
      "pkr_risk_value": "PKR 5,000,000", // MUST be a real number extracted from text. No 'X's.
      "impact_description": "..."
    }
  ],
  "actions": [
    {
      "id": "A1",
      "title": "Launch Marketing Campaign to [Mitigate Risk / Promote Opportunity]",
      "details": "Create a public advertisement / social media post to...", // Explicitly mention creating an ad/marketing.
      "projected_impact": "PKR +2,000,000" // MUST include the financial impact/price extracted from data.
    },
    {
      "id": "A2",
      "title": "...",
      "details": "...",
      "projected_impact": "..."
    }
  ]
}

Extract ALL POSSIBLE risks and execution plans found in the data. Do not limit the count. Keep descriptions point-to-point. Show all extracted prices clearly.
"""

class SupervisorAgent:
    def __init__(self, state_manager, logger):
        self.state_manager = state_manager
        self.logger = logger
        self.processor = DocumentProcessorAgent()
        self.processor.logger = logger

    def log_trace(self, step_name, input_data, output_data):
        if self.logger:
            self.logger.log_step(
                self.__class__.__name__, step_name, input_data, output_data
            )

    async def run_workflow(self, file_paths: list):
        self.logger.start_new_trace()
        self.log_trace("Workflow started", {"files": file_paths}, None)

        # Step 1: Extract text from all files
        all_text = ""
        for path in file_paths:
            text = await self.processor.process(path)
            all_text += f"\n\n--- Document: {path.split('/')[-1]} ---\n{text}"

        # Step 2: Send to Gemini via standard API key call
        result = await self._run_analysis(all_text, file_paths)
        
        # Add to history
        file_names = ", ".join([p.split('/')[-1] for p in file_paths])
        self.state_manager.add_action_log(f"Analyzed Documents: {file_names}", "Success")
        
        return result

    async def run_workflow_from_content(self, content: str, source_name: str):
        self.logger.start_new_trace()
        self.log_trace("URL Workflow started", {"source": source_name}, None)

        result = await self._run_analysis(content, [source_name])
        
        # Add to history
        self.state_manager.add_action_log(f"Analyzed URL: {source_name}", "Success")
        
        return result

    async def _run_analysis(self, content: str, sources: list) -> dict:
        # Only pass document content — no old state to prevent data mixing
        prompt = f"""
=== DOCUMENT CONTENT TO ANALYZE ===
{content[:15000]}  
=== END OF CONTENT ===

Generate the strategic intelligence report as a JSON object. Base ALL data points strictly on the above content.
"""
        response_text = await self.processor.chat(prompt, SYSTEM_PROMPT)
        self.log_trace("Gemini response received", None, {"length": len(response_text)})

        # Robust JSON extraction
        json_str = response_text.strip()
        if "```json" in json_str:
            json_str = json_str.split("```json")[1].split("```")[0].strip()
        elif "```" in json_str:
            json_str = json_str.split("```")[1].split("```")[0].strip()

        try:
            report_data = json.loads(json_str)
            
            # Extract and update metrics
            if "extracted_metrics" in report_data:
                metrics = report_data.pop("extracted_metrics")
                self.state_manager.update_metrics({
                    "monthly_revenue_pkr": metrics.get("monthly_revenue_pkr", "0"),
                    "operating_costs_pkr": metrics.get("operating_costs_pkr", "0"),
                    "compliance_score": metrics.get("compliance_score", 0)
                })
                self.state_manager.update_efficiency_trend(metrics.get("overall_efficiency", 5.0))
                
        except Exception as e:
            self.log_trace("JSON parse failed", {"raw": response_text[:500]}, str(e))
            report_data = {
                "main_feeds": [{"title": "Parse Error", "content": f"Raw response: {response_text[:300]}"}],
                "risks": [],
                "actions": []
            }

        self.log_trace("Analysis complete", None, {
            "feeds": len(report_data.get("main_feeds", [])),
            "risks": len(report_data.get("risks", [])),
            "actions": len(report_data.get("actions", []))
        })

        return {
            "report": report_data,
            "trace_id": self.logger.current_trace_id,
            "files_processed": sources
        }
