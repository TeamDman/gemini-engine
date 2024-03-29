# gemini_file_upload.py
import googleapiclient.discovery
import requests
import sys
from googleapiclient.http import MediaFileUpload
import mimetypes
import os

api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    raise Exception("GEMINI_API_KEY environment variable is not set.")


def upload_file(file_path, file_mimetype):
    GENAI_DISCOVERY_URL = f"https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta&key={api_key}"
    discovery_docs = requests.get(GENAI_DISCOVERY_URL)
    genai_service = googleapiclient.discovery.build_from_document(
        discovery_docs.json(), developerKey=api_key
    )

    # Prepare file upload
    media = MediaFileUpload(file_path, mimetype=file_mimetype)
    body = {"file": {"displayName": file_path.split("/")[-1]}}

    # Upload file and get URL
    create_file_response = (
        genai_service.media().upload(media_body=media, body=body).execute()
    )
    file_uri = create_file_response["file"]["uri"]

    return file_uri


if __name__ == "__main__":
    file_path = sys.argv[1]
    file_mimetype = sys.argv[2]
    file_url = upload_file(file_path, file_mimetype)
    print(file_url)
