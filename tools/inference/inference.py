# gemini_invoke.py
import googleapiclient.discovery
import requests
import sys
import sys
import json
from googleapiclient.discovery import build
import os
from dataclasses import dataclass, asdict
from dacite import from_dict
import httplib2

@dataclass(frozen=True)
class PayloadFile:
    url: str
    mimetype: str


@dataclass(frozen=True)
class Payload:
    prompt: str
    files: list[PayloadFile]


def info(*args):
    for arg in args:
        sys.stderr.write(f"{arg} ")
    sys.stderr.write("\n")


def build_service(api_key):
    GENAI_DISCOVERY_URL = f"https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta&key={api_key}"
    discovery_docs = requests.get(GENAI_DISCOVERY_URL)
    genai_service = googleapiclient.discovery.build_from_document(
        discovery_docs.json(),
        developerKey=api_key,
        http=httplib2.Http(timeout=60 * 5),
    )
    return genai_service.models()


def invoke_gemini(models_api, payload: Payload):
    # Prepare request body
    params = {
        "model": "models/gemini-1.5-pro-latest",
        "body": {
            "contents": [
                {
                    "parts": [
                        {"text": payload.prompt},
                    ]
                }
            ]
        },
    }

    # Include files in request
    if not payload.files:
        info("No files detected in request")
    for file in payload.files:
        print(f"Including file {file.url} ({file.mimetype}) in request")
        params["body"]["contents"][0]["parts"].append(
            {"file_data": {"file_uri": file.url, "mime_type": file.mimetype}}
        )

    # Send request and print response
    resp = models_api.generateContent(**params).execute()

    # Save response
    if not os.path.exists("responses"):
        os.makedirs("responses")
    history_file = f"responses/{len(os.listdir('responses'))}.json"
    history_entry = {
        "payload": asdict(payload),
        "response": resp,
    }
    with open(history_file, "w", encoding="utf-8") as f:
        json.dump(history_entry, f, indent=4)

    # Print response
    print(resp["candidates"][0]["content"]["parts"][0]["text"])


if __name__ == "__main__":
    # Build API service
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise Exception("GEMINI_API_KEY environment variable is not set.")
    models_api = build_service(api_key)

    # Parse payload
    file = sys.argv[1]
    with open(file, "r", encoding="utf-8") as f:
        payload = json.load(f)
    payload = from_dict(data_class=Payload, data=payload)
    # info(payload)

    # Invoke Gemini
    invoke_gemini(models_api, payload)
