if (-not (Test-Path Env:GEMINI_API_KEY)) {
    Write-Warning "GEMINI_API_KEY environment variable not set."
    return
}

Push-Location prompts
$env:SHELL = "pwsh"
$chosenPromptName = fzf --preview "bat {}" --prompt "Select prompt: " --header "Available Prompts"
if ([string]::IsNullOrWhiteSpace(($chosenPromptName))) {
    Write-Warning "No prompt selected. Exiting..."
    return
}
Pop-Location

# Read prompt content
$prompt = Get-Content -Raw "prompts\$chosenPromptName"
# Prepare payload and call Python script
$payload = [pscustomobject]@{
    prompt        = $prompt
    file_url      = $file.url
    file_mimetype = $file.mimetype
}
$file = New-TemporaryFile
$payload | ConvertTo-Json | Set-Content -Path $file.FullName
try {
    python .\tools\inference\inference.py "$($file.FullName)" | code -
}
finally {
    Remove-Item -Path $file.FullName
}