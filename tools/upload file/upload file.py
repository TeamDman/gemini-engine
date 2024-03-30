import json
import googleapiclient.discovery
import requests
import sys
from googleapiclient.http import MediaFileUpload
import os
from dataclasses import dataclass, asdict
from dacite import from_dict

@dataclass(frozen=True)
class PayloadFile:
    path: str
    mimetype: str
    displayname: str

@dataclass(frozen=True)
class Payload:
    files: list[PayloadFile]

@dataclass(frozen=True)
class OutputFile:
    path: str
    mimetype: str
    displayname: str
    url: str

def info(*args):
    for arg in args:
        sys.stderr.write(f"{arg} ")
    sys.stderr.write("\n")

def build_service(api_key):
    GENAI_DISCOVERY_URL = f"https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta&key={api_key}"
    discovery_docs = requests.get(GENAI_DISCOVERY_URL)
    genai_service = googleapiclient.discovery.build_from_document(
        discovery_docs.json(), developerKey=api_key
    )
    return genai_service.media()

def upload_file(media_api, file: PayloadFile):
    # Prepare file upload
    media = MediaFileUpload(file.path, mimetype=file.mimetype)
    body = {"file": {"displayName": file.displayname}}

    # Upload file and get URL
    info("Uploading", file)
    create_file_response = media_api.upload(media_body=media, body=body).execute()

    # Print output
    output = OutputFile(
        path=file.path,
        mimetype=file.mimetype,
        displayname=file.displayname,
        url=create_file_response["file"]["uri"],
    )
    print(json.dumps(asdict(output)))


if __name__ == "__main__":
    # Build API service
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise Exception("GEMINI_API_KEY environment variable is not set.")
    media_api = build_service(api_key)

    # Parse payload
    file = sys.argv[1]
    with open(file, "r", encoding="utf-8") as f:
        payload = json.load(f)
    # info(payload)
    payload = from_dict(data_class=Payload, data=payload)

    # Upload files
    for file in payload.files:
        upload_file(media_api, file)
