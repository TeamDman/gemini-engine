while ($true) {
    $chosenFileName = $cachedFiles.Keys | fzf
    if ([string]::IsNullOrEmpty($chosenFileName)) {
        $file = [PSCustomObject]@{
            url = $null
            mimetype = $null
        }
    } else {
        $file = $cachedFiles[$chosenFileName]
    }
    $prompt = Read-Host "Prompt"
    if ([string]::IsNullOrWhiteSpace($prompt)) {
        break
    }
    $payload = [pscustomobject]@{
        prompt = $prompt
        file_url = $file.url
        file_mimetype = $file.mimetype
    }
    python inference.py $($payload | ConvertTo-Json)
    pause
}