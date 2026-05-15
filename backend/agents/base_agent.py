import os
from typing import Any, Dict
import google.generativeai as genai
from dotenv import load_dotenv
from core.logger import TraceLogger

load_dotenv()

class BaseAgent:
    def __init__(self, name: str, role: str, logger: TraceLogger = None):
        self.name = name
        self.role = role
        self.logger = logger
        self.model_name = "gemini-1.5-flash"
        api_key = os.getenv("GOOGLE_API_KEY")
        if api_key:
            genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel(self.model_name)

    async def chat(self, prompt: str, system_instruction: str = None) -> str:
        if system_instruction:
            self.model = genai.GenerativeModel(
                model_name=self.model_name,
                system_instruction=system_instruction
            )
        
        response = self.model.generate_content(prompt)
        return response.text

    def log_trace(self, step: str, input_data: Any, output_data: Any):
        print(f"[{self.name}] {step}")
        if self.logger:
            self.logger.log_step(self.name, step, input_data, output_data)
