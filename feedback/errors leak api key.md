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

```
---------------------------------------------------------------------------
HttpError                                 Traceback (most recent call last)
Cell In[39], line 10
      4 contents = {"contents": [{ 
      5   "parts":[
      6     {"text": prompt},
      7     {"file_data": {"file_uri": file_uri, "mime_type": file_mimetype}}]
      8 }]}
      9 genai_request = genai_service.models().generateContent(model=model, body=contents)
---> 10 resp = genai_request.execute()
     11 print(len(resp["candidates"]))

File c:\Users\TeamD\.conda\envs\sfm\lib\site-packages\googleapiclient\_helpers.py:130, in positional.<locals>.positional_decorator.<locals>.positional_wrapper(*args, **kwargs)
    128     elif positional_parameters_enforcement == POSITIONAL_WARNING:
    129         logger.warning(message)
--> 130 return wrapped(*args, **kwargs)

File c:\Users\TeamD\.conda\envs\sfm\lib\site-packages\googleapiclient\http.py:938, in HttpRequest.execute(self, http, num_retries)
    936     callback(resp)
    937 if resp.status >= 300:
--> 938     raise HttpError(resp, content, uri=self.uri)
    939 return self.postproc(resp, content)

HttpError: <HttpError 400 when requesting https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent?key=LITERALLY MY API KEY PLS REDACT&alt=json returned "Request contains an invalid argument.". Details: "Request contains an invalid argument.">
```

in the error, it doesn't censor the API key.
If I were to commit my jupter notebook without clearing cell outputs, it would leak my API key.
Please redact the API key in error messages.