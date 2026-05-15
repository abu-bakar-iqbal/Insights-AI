# Insights AI: Autonomous Content-to-Action Agent

## 1. Vision
Insights AI is a Pakistan-focused agentic system designed to bridge the gap between complex unstructured data (government reports, business articles, financial news) and tangible business actions. It doesn't just summarize; it reasons about the impact on the local ecosystem and simulates execution.

## 2. Multi-Agent Architecture (Antigravity Powered)

### Core Orchestrator: `SupervisorAgent`
- **Role**: Workflow controller.
- **Responsibility**: Routes data between agents, validates outputs against user constraints, and manages the global state.
- **Platform**: Google Antigravity.

### Ingestion: `DocumentProcessorAgent`
- **Role**: Data Extraction.
- **Responsibility**: Uses OCR and semantic parsing to convert PDFs/Images/Articles into clean, structured text.
- **Tools**: PyMuPDF, Gemini Vision (if needed).

### Intelligence: `InsightExtractorAgent`
- **Role**: Deep Reasoning.
- **Responsibility**: Identifies non-obvious insights specific to Pakistan (e.g., impact of a new tax levy on specific sectors).
- **Prompting**: Chain-of-Thought (CoT) reasoning for "Insight Discovery".

### Analysis: `ImpactAnalystAgent`
- **Role**: Risk & Benefit Assessment.
- **Responsibility**: Quantitative and qualitative analysis. "How does this change our bottom line in PKR?"
- **Output**: Impact Score, Risk Level, Growth Opportunities.

### Planning: `ActionGeneratorAgent`
- **Role**: Strategic Planning.
- **Responsibility**: Generates 3 SMART (Specific, Measurable, Achievable, Relevant, Time-bound) actions.
- **Example**: "Prepare a revised procurement budget following the 2% increase in Sales Tax."

### Execution: `ExecutorAgent`
- **Role**: Simulation & Tool Use.
- **Responsibility**: Executes the selected action in a simulated environment.
- **Simulations**: 
    - Draft an email/proposal.
    - Update a local "Digital Twin" system state.
    - Generate a visualization of "System State: After".

## 3. Data Flow
1. **User Uploads PDF** via Flutter App.
2. **FastAPI Backend** receives file and initiates Antigravity Workflow.
3. **Supervisor Agent** triggers agents in sequence.
4. **Traces** are recorded at every step for auditability.
5. **Actionable Insights** are sent back to the App.
6. **User selects Action** -> Executor simulates -> "Before vs After" results displayed.

## 4. Simulation Mechanics
We maintain a `system_state.json` file representing a hypothetical business/government department.
- **Before**: Current budgets, policies, and communications.
- **Action**: e.g., "Implement Cost Cutting".
- **After**: Updated budget projections and draft policy documents.
