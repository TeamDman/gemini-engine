# Ensure API key is present
if (-not (Test-Path Env:GEMINI_API_KEY)) {
    Write-Warning "GEMINI_API_KEY environment variable not set."
    return
}

# Get list of uploaded files
if (Test-Path -Path .\files.json) {
    $uploaded_files = Get-Content -Path "files.json" | ConvertFrom-Json -AsHashtable
} else {
    $uploaded_files = @{}
}

# Pick files
$chosen_file_keys = $uploaded_files.Keys `
| fzf `
--multi `
--prompt "Select files: " `
--bind "ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all"


# Pick prompt
Push-Location prompts
$env:SHELL="pwsh"
$chosenPromptName = fzf `
    --preview "bat {}" `
    --prompt "Select prompt: " `
    --header "Available Prompts"
Pop-Location
if (-not $chosenPromptName) {
    Write-Warning "No prompt selected. Exiting..."
    return
}
$prompt = Get-Content -Raw "prompts\$chosenPromptName"

# Prepare payload
$payload = [pscustomobject]@{
    prompt = $prompt
    files = @()
}
foreach ($key in $chosen_file_keys) {
    $payload.files += $uploaded_files[$key]
}
$file = New-TemporaryFile
$payload | ConvertTo-Json | Set-Content -Path $file.FullName

# Invoke model followed by cleanup
try {
    python .\tools\inference\inference.py "$($file.FullName)" | code -
} finally {
    Remove-Item -Path $file.FullName
}