https://discord.com/channels/1009525727504384150/1182420115661267085/1222619212577640650

```python
# Prepare file to upload to GenAI File API
file_path = "beans.txt"

# media = MediaFileUpload(file_path, mimetype="application/json")
media = MediaFileUpload(file_path, mimetype=mimetypes.guess_type(file_path)[0])
body = {"file": {"displayName": "A text file"}}

# Upload file
create_file_request = genai_service.media().upload(media_body=media, body=body)
create_file_response = create_file_request.execute()
file_uri = create_file_response["file"]["uri"]
file_mimetype = create_file_response["file"]["mimeType"]
print("Uploaded file: " + file_uri)
```
This works
Uploaded file: https://generativelanguage.googleapis.com/v1beta/files/y...

This fails

```python
# Make Gemini 1.5 API LLM call
prompt = "Describe the contents of the text file"
model = "models/gemini-1.5-pro-latest"
contents = {"contents": [{ 
  "parts":[
    {"text": prompt},
    {"file_data": {"file_uri": file_uri, "mime_type": file_mimetype}}]
}]}
genai_request = genai_service.models().generateContent(model=model, body=contents)
resp = genai_request.execute()
print(len(resp["candidates"]))
```
HttpError: <HttpError 400 when requesting https:...
returned "Request contains an invalid argument.". Details: "Request contains an invalid argument."

the FAQ doc lists image/webp as supported but I received the same error when trying a webp file, mimetypes.py doesn't contain an entry for it from what I can tell so this happens which doesn't prevent the genai_servbice.media().upload from working but it fails at inference time

```python
mimetypes.guess_type("abc.webp")
> (None,None)
```

