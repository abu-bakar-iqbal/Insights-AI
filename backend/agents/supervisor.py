import json
from agents.processor import DocumentProcessorAgent

SYSTEM_PROMPT = """
You are an Elite Strategic Advisor specializing in the Pakistan market.

CRITICAL RULE 1: Only use information from the provided document text. Do NOT invent facts.
CRITICAL RULE 2: EXTREME BREVITY. Assume the CEO has exactly 10 seconds to read the entire report. Use ONLY point-to-point data. No fluff, no detailed paragraphs. Maximum 15 words for any description or content field.
CRITICAL RULE 3: EXTRACT REAL METRICS. You must extract exact numerical values (PKR, USD, prices, costs, compliance scores) directly from the text. NEVER use placeholders like 'X,XXX' or leave them as '0' or 'PKR 0'. If exact numbers for operating_costs_pkr or compliance_score aren't explicitly found in the text, you MUST make a highly realistic, educated, data-driven estimate based on the context (e.g. estimate operating costs as a reasonable 1-5% of the revenue, and compliance score between 70% and 98% based on the audit success or failure rates described). Always provide complete, premium metrics data.
CRITICAL RULE 4: FIRST ACTION IS ALWAYS MARKETING. The very first execution plan (id: "A1") MUST always be a public advertising, social media, or marketing campaign designed to reduce the biggest risk or promote the biggest opportunity found in the data.
CRITICAL RULE 5: FORMAT LARGE NUMBERS WITH M OR B. Any monetary value or large numerical figure (revenue, costs, impacts, risks) MUST be formatted using M (Millions) or B (Billions) suffix, e.g. "PKR 5.2M" or "PKR 2.5B" instead of raw digits like "5,200,000" or "2,500,000,000".

Analyze the provided content and generate a CEO-level strategic intelligence report.
Your output MUST be valid JSON in exactly this format (no extra text outside the JSON):

{
  "extracted_metrics": {
    "monthly_revenue_pkr": "...", // Format with M/B (e.g. "5.2M")
    "operating_costs_pkr": "...", // Format with M/B (e.g. "1.1M")
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
      "pkr_risk_value": "5.0M", // MUST be formatted using M or B suffix. No raw long digits.
      "impact_description": "..."
    }
  ],
  "actions": [
    {
      "id": "A1",
      "title": "Launch Marketing Campaign to [Mitigate Risk / Promote Opportunity]",
      "details": "Create a public advertisement / social media post to...", // Explicitly mention creating an ad/marketing.
      "projected_impact": "+2.0M" // MUST be formatted using M or B suffix. No raw long digits.
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
        try:
            response_text = await self.processor.chat(prompt, SYSTEM_PROMPT)
            self.log_trace("Gemini response received", None, {"length": len(response_text)})

            # Robust JSON extraction
            json_str = response_text.strip()
            if "```json" in json_str:
                json_str = json_str.split("```json")[1].split("```")[0].strip()
            elif "```" in json_str:
                json_str = json_str.split("```")[1].split("```")[0].strip()
        except Exception as e:
            self.log_trace("Gemini API Error", None, {"error": str(e)})
            json_str = '{"extracted_metrics": {}, "main_feeds": [{"title": "API Error", "content": "The Google Gemini API is currently blocked or returning an error. Please verify your API Key in the backend .env file."}], "risks": [], "actions": []}'

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
