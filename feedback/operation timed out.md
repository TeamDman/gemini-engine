Reading from stdin via: C:\Users\TeamD\AppData\Local\Temp\code-stdin-xNm
Traceback (most recent call last):
  File "D:\Repos\ml\gemini-engine\inference.py", line 62, in <module>
    invoke_gemini(payload)
  File "D:\Repos\ml\gemini-engine\inference.py", line 39, in invoke_gemini
    resp = genai_service.models().generateContent(model=model, body=contents).execute()
  File "C:\Users\TeamD\.conda\envs\sfm\lib\site-packages\googleapiclient\_helpers.py", line 130, in positional_wrapper
    return wrapped(*args, **kwargs)
  File "C:\Users\TeamD\.conda\envs\sfm\lib\site-packages\googleapiclient\http.py", line 923, in execute
    resp, content = _retry_request(
  File "C:\Users\TeamD\.conda\envs\sfm\lib\site-packages\googleapiclient\http.py", line 222, in _retry_request
    raise exception
  File "C:\Users\TeamD\.conda\envs\sfm\lib\site-packages\googleapiclient\http.py", line 191, in _retry_request
    resp, content = http.request(uri, method, *args, **kwargs)
  File "C:\Users\TeamD\.conda\envs\sfm\lib\site-packages\httplib2\__init__.py", line 1724, in request
    (response, content) = self._request(
  File "C:\Users\TeamD\.conda\envs\sfm\lib\site-packages\httplib2\__init__.py", line 1444, in _request
    (response, content) = self._conn_request(conn, request_uri, method, body, headers)
  File "C:\Users\TeamD\.conda\envs\sfm\lib\site-packages\httplib2\__init__.py", line 1396, in _conn_request
    response = conn.getresponse()
  File "C:\Users\TeamD\.conda\envs\sfm\lib\http\client.py", line 1375, in getresponse
    response.begin()
  File "C:\Users\TeamD\.conda\envs\sfm\lib\http\client.py", line 318, in begin
    version, status, reason = self._read_status()
  File "C:\Users\TeamD\.conda\envs\sfm\lib\http\client.py", line 279, in _read_status
    line = str(self.fp.readline(_MAXLINE + 1), "iso-8859-1")
  File "C:\Users\TeamD\.conda\envs\sfm\lib\socket.py", line 705, in readinto
    return self._sock.recv_into(b)
  File "C:\Users\TeamD\.conda\envs\sfm\lib\ssl.py", line 1274, in recv_into
    return self.read(nbytes, buffer)
  File "C:\Users\TeamD\.conda\envs\sfm\lib\ssl.py", line 1130, in read
    return self._sslobj.read(len, buffer)
TimeoutError: The read operation timed out