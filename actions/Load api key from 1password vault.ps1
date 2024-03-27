$env:GEMINI_API_KEY = op read "op://Private/Google AI Studio API key/credential"
Write-Host "API Key loaded into GEMINI_API_KEY environment variable."