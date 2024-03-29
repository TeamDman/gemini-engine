if (-not (Test-Path Env:GEMINI_API_KEY)) {
    Write-Warning "GEMINI_API_KEY environment variable not set."
    return
}

# Pick the prompt
Push-Location prompts
$env:SHELL="pwsh"
$prompt = fzf `
    --preview "bat {}" `
    --prompt "Select prompt: " `
    --header "Available Prompts"
Pop-Location

if ([string]::IsNullOrWhiteSpace($prompt)) {
    Write-Warning "No prompt selected. Exiting..."
    return
}

# Perform the count
Write-Host "Counting tokens in $prompt"
$count = python ".\tools\count file tokens\count file tokens.py" ".\prompts\$prompt"
Write-Host "Token count: $count"