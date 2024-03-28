# Select file and prompt using fzf
$chosenFileName = $cachedFiles.Keys | fzf
$file = $cachedFiles[$chosenFileName]
Push-Location prompts
$chosenPromptName = fzf
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