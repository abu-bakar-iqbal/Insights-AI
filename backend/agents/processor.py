import os
import fitz  # PyMuPDF
import httpx
from bs4 import BeautifulSoup
from agents.base_agent import BaseAgent

class DocumentProcessorAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            "Document Processor",
            "You extract and clean text from documents and websites."
        )

    async def process(self, file_path: str) -> str:
        """Extract text from a file (PDF or plain text)."""
        self.log_trace("Processing file", {"path": file_path}, None)
        ext = os.path.splitext(file_path)[1].lower()
        if ext == ".pdf":
            text = self._extract_pdf(file_path)
        else:
            text = self._extract_text(file_path)
        self.log_trace("File processed", None, {"chars": len(text)})
        return text

    async def process_url(self, url: str) -> str:
        """Scrape and clean text from a web URL."""
        self.log_trace("Scraping URL", {"url": url}, None)
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(url)
                soup = BeautifulSoup(response.text, "html.parser")
                for tag in soup(["script", "style", "nav", "footer"]):
                    tag.decompose()
                lines = [l.strip() for l in soup.get_text().splitlines()]
                text = "\n".join(l for l in lines if l)
                self.log_trace("URL scraped", None, {"chars": len(text)})
                return text
        except Exception as e:
            return f"Error scraping URL: {str(e)}"

    def _extract_pdf(self, path: str) -> str:
        doc = fitz.open(path)
        return "\n".join(page.get_text() for page in doc)

    def _extract_text(self, path: str) -> str:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()
