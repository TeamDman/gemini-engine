if (-not (Test-Path Env:GEMINI_API_KEY)) {
    Write-Warning "GEMINI_API_KEY environment variable not set."
    return
}

# Select file and prompt using fzf
$chosenFileName = $cachedFiles.Keys | fzf --prompt "Select file: " --header "Cached Files"
$file = $cachedFiles[$chosenFileName]
Push-Location prompts
$env:SHELL="pwsh"
$chosenPromptName = fzf --preview "bat {}" --prompt "Select prompt: " --header "Available Prompts"
Pop-Location
# Read prompt content
$prompt = Get-Content -Raw "prompts\$chosenPromptName"
# Prepare payload and call Python script
$payload = [pscustomobject]@{
    prompt = $prompt
    file_url = $file.url
    file_mimetype = $file.mimetype
}
$file = New-TemporaryFile
$payload | ConvertTo-Json | Set-Content -Path $file.FullName
try {
    python inference.py "$($file.FullName)"
} finally {
    Remove-Item -Path $file.FullName
}