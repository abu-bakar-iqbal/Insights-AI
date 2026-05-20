import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import json

import os

class Mailer:
    def __init__(self, smtp_settings=None):
        self.host = os.getenv("SMTP_HOST")
        port_val = os.getenv("SMTP_PORT", "587")
        self.port = int(port_val) if port_val.isdigit() else 587
        self.username = os.getenv("SMTP_USERNAME")
        self.password = os.getenv("SMTP_PASSWORD")

    def send_report(self, recipients, subject, report_data):
        if not self.host or not self.username or not self.password or not recipients:
            print("[Mailer] SMTP not configured or no recipients. Skipping email.")
            return False

        try:
            msg = MIMEMultipart()
            msg['From'] = self.username
            msg['To'] = ", ".join(recipients)
            msg['Subject'] = subject

            # Format the report nicely
            body = "Insights AI - Strategic Report\n\n"
            if isinstance(report_data, dict):
                metrics = report_data.get("extracted_metrics", {})
                body += "--- METRICS ---\n"
                for k, v in metrics.items():
                    body += f"{k}: {v}\n"
                
                body += "\n--- RISKS ---\n"
                for risk in report_data.get("risks", []):
                    body += f"- {risk.get('title')} (Severity: {risk.get('severity')})\n"
                
                body += "\n--- ACTIONS ---\n"
                for action in report_data.get("actions", []):
                    body += f"- {action.get('title')}: {action.get('details')}\n"
            else:
                body += str(report_data)

            msg.attach(MIMEText(body, 'plain'))

            server = smtplib.SMTP(self.host, self.port)
            server.starttls()
            server.login(self.username, self.password)
            server.send_message(msg)
            server.quit()
            print(f"[Mailer] Successfully sent report to {len(recipients)} recipients.")
            return True
        except Exception as e:
            print(f"[Mailer] Failed to send email: {e}")
            return False
