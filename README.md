# Insights AI Agent - Google Antigravity Hackathon

## 🚀 Overview
Insights AI is an autonomous **Content-to-Action** system built for the Pakistan market. It ingests unstructured data (PDFs, reports, news), extracts deep strategic insights using multi-agent reasoning, and simulates the execution of high-impact business actions.

## 🧠 Agent Architecture (Google Antigravity)
- **SupervisorAgent**: Orchestrates the planning and execution loop.
- **DocumentProcessorAgent**: Semantic extraction from unstructured PDFs.
- **InsightExtractorAgent**: Chain-of-Thought reasoning for localized insights.
- **ImpactAnalystAgent**: Quantitative impact analysis (PKR-based).
- **ActionGeneratorAgent**: Pragmatic recommendation engine.
- **ExecutorAgent**: Digital Twin simulation and state transformation.

## 📱 Mobile App (Flutter)
- **Insight Dashboard**: Visualize agent findings.
- **Impact Analysis**: Risk vs Opportunity scoring.
- **Action Simulation**: Side-by-side "Before vs After" metrics showing the resulting system state.

## 🛠 Tech Stack
- **AI**: Gemini 1.5 Pro via Google Generative AI.
- **Orchestration**: Google Antigravity.
- **Backend**: FastAPI (Python 3.10+).
- **Frontend**: Flutter (Material 3).
- **Storage**: Local State Manager (Digital Twin JSON).

## 🏃 Setup Instructions
### Backend
1. `cd backend`
2. `pip install -r requirements.txt`
3. Create `.env` with `GOOGLE_API_KEY`.
4. `python main.py`

### Mobile
1. `cd mobile_app`
2. `flutter pub get`
3. `flutter run`

## 📊 Evaluation Criteria Alignment
- **Antigravity (25%)**: Core orchestration uses Antigravity patterns.
- **Agentic Reasoning (20%)**: Multi-agent delegation and validation.
- **Insight Quality (20%)**: Pakistan-specific deep reasoning (non-generic).
- **Execution Simulation (Mandatory)**: Full "Before vs After" state visualization.
