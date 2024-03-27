# Select file and prompt using fzf
$chosenFileName = $cachedFiles.Keys | fzf
$file = $cachedFiles[$chosenFileName]
Push-Location prompts
$chosenPromptName = fzf
Pop-Location
# Read prompt content
$prompt = Get-Content -Raw prompts\$chosenPromptName
# Prepare payload and call Python script
$payload = [pscustomobject]@{
    prompt = $prompt
    file_url = $file.url
    file_mimetype = $file.mimetype
}
python inference.py $($payload | ConvertTo-Json)