import os
import time
from typing import Any, List
import google.generativeai as genai
from dotenv import load_dotenv

# Load env explicitly from backend directory
backend_dir = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(backend_dir, '..', '.env'))

class BaseAgent:
    def __init__(self, name: str, role: str, logger=None):
        self.name = name
        self.role = role
        self.logger = logger
        self.model_name = "gemini-flash-latest"

        api_key = os.getenv("GOOGLE_API_KEY")
        if not api_key:
            raise EnvironmentError(
                "GOOGLE_API_KEY not found. Please add it to backend/.env"
            )
        genai.configure(api_key=api_key)

    async def chat(self, prompt: str, system_instruction: str = None) -> str:
        """Standard text-based Gemini call using API key."""
        model = genai.GenerativeModel(
            model_name=self.model_name,
            system_instruction=system_instruction
        )
        response = model.generate_content(prompt)
        return response.text

    def log_trace(self, step: str, input_data: Any, output_data: Any):
        print(f"[{self.name}] {step}")
        if self.logger:
            self.logger.log_step(self.name, step, input_data, output_data)
