# Select response file
$chosenResponseFile = Get-ChildItem -Path responses -Filter "*.json" `
    | Select-Object -ExpandProperty Name `
    | Sort-Object -Descending `
    | fzf --no-sort

# Check if file was selected
if ([string]::IsNullOrEmpty($chosenResponseFile)) {
    Write-Host "No response file selected."
    return
}

# Read response data
$responseData = Get-Content -Raw -Path "responses/$chosenResponseFile" `
    | ConvertFrom-Json

# Extract the "good part"
# (Modify this logic based on the actual response structure)
$extracted = $responseData.response.candidates.content.parts.text

# Open the extracted content in VSCode
$extracted | code -
