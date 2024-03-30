# Load cached data
if (Test-Path -Path .\files.json) {
    $cachedFiles = Get-Content -Path "files.json" | ConvertFrom-Json -AsHashtable
  }
  else {
    $cachedFiles = @{}
  }

# Pick files to include
$files = @()
$chosen = $cachedFiles.Keys `
| fzf `
    --multi `
    --header "Select files to include in prompt" `
    --bind "ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all"
if (-not $chosen) {
    Write-Host "No files selected."
} else {
    foreach ($file in $chosen) {
        $files += $cachedFiles[$file]
        Write-Host "Added $file"
    }
}

# Begin inference loop
while ($true) {
    Write-Host "Including $($files.Count) files in prompt..."
    # Pick prompt
    $prompt = Read-Host "Prompt"
    if ([string]::IsNullOrWhiteSpace($prompt)) {
        return
    }

    # Prepare payload
    $payload = [pscustomobject]@{
        prompt = $prompt
        files = $files
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
    
    # Leave the result on the screen for a moment
    pause
}