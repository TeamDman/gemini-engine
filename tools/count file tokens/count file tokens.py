import googleapiclient.discovery
import requests
import sys
import sys
import json
from googleapiclient.discovery import build
import os

def count_tokens(text: str, api_key: str) -> int:
    GENAI_DISCOVERY_URL = f"https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta&key={api_key}"
    discovery_docs = requests.get(GENAI_DISCOVERY_URL)
    genai_service = googleapiclient.discovery.build_from_document(
        discovery_docs.content, developerKey=api_key)
    models_api = genai_service.models()
    params = {
        "model": "models/gemini-1.5-pro-latest",
        "body": {
            "contents": [
                {
                    "parts": [
                        {"text": text},
                    ]
                }
            ]
        },
    }
    request = models_api.countTokens(**params)
    response = request.execute()
    return response["totalTokens"]

if __name__ == "__main__":
    # Load API key
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise Exception("GEMINI_API_KEY environment variable is not set.")

    # Load content
    file = sys.argv[1]
    with open(file, "r", encoding="utf-8") as f:
        text = f.read()

    # Perform count
    print(count_tokens(text, api_key))
