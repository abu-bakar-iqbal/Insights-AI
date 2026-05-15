from agents.base_agent import BaseAgent
import fitz  # PyMuPDF

class DocumentProcessorAgent(BaseAgent):
    def __init__(self):
        super().__init__("DocumentProcessor", "Extracts structured text from PDFs and images.")

    async def process(self, file_path: str) -> str:
        self.log_trace("Processing started", {"file": file_path}, None)
        
        text = ""
        if file_path.endswith(".pdf"):
            doc = fitz.open(file_path)
            for page in doc:
                text += page.get_text()
        else:
            # For TXT or other files
            with open(file_path, 'r', encoding='utf-8') as f:
                text = f.read()
        
        # Clean text using Gemini to ensure it's high quality
        prompt = f"Clean and structure the following extracted text for downstream analysis. Maintain all financial figures and dates: \n\n{text[:10000]}"
        cleaned_text = await self.chat(prompt, "You are a precise data extractor focusing on Pakistani business context.")
        
        self.log_trace("Processing completed", None, {"text_length": len(cleaned_text)})
        return cleaned_text
