# gemini_invoke.py
import googleapiclient.discovery
import requests
import sys
import sys
import json
from googleapiclient.discovery import build
import os
api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    raise Exception("GEMINI_API_KEY environment variable is not set.")

def invoke_gemini(payload):
  # print(payload)
  GENAI_DISCOVERY_URL = f"https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta&key={api_key}"
  discovery_docs = requests.get(GENAI_DISCOVERY_URL)
  genai_service = googleapiclient.discovery.build_from_document(discovery_docs.json(), developerKey=api_key)

  # Extract prompt and file URL from payload
  prompt = payload["prompt"]
  file_url = payload["file_url"]
  file_mimetype = payload["file_mimetype"]

  # Prepare request body
  parts = [
    {"text": prompt}, 
  ]
  if file_url:
     print("File url detected, including in request")
     parts.append({"file_data": {"file_uri": file_url, "mime_type": file_mimetype}})
  contents = {
    "contents": [
      {
        "parts": parts
      }
    ]
  }

  # Send request and print response
  model = "models/gemini-1.5-pro-latest"
  resp = genai_service.models().generateContent(model=model, body=contents).execute()
  print(resp)

if __name__ == "__main__":
  payload = json.loads(sys.argv[1])
  invoke_gemini(payload)