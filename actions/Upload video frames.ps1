# Load cached data
if (Test-Path -Path .\files.json) {
    $cachedFiles = Get-Content -Path "files.json" | ConvertFrom-Json -AsHashtable
}
else {
    $cachedFiles = @{}
}
  

# Pick the video
$video = Get-ChildItem -Directory '.\video frames' `
| Select-Object -ExpandProperty Name
| fzf --header "Select a video"

if (-not $video) {
    Write-Host "No video selected. Exiting..."
    return
}


# Prepare files
$path = Join-Path -Path ".\video frames" -ChildPath $video
$files = Get-ChildItem -LiteralPath $path `
| ForEach-Object {
    $path = $_.FullName
    $mimetype = "image/png" # Assuming PNG format for frames
    return [PSCustomObject]@{
        path        = $path
        mimetype    = $mimetype
        displayname = "$basename - 1 FPS - Frame $($_.BaseName)"
    }
}
Write-Host "Found $($files.Count) frames in $video."

# Overwrite check
$duplicates = $files | Where-Object { $cachedFiles.ContainsKey($_.path) }
if ($duplicates) {
  Write-Host "The following files already exist in the cache:"
  foreach ($duplicate in $duplicates) {
    Write-Host "-  $($duplicate.displayname)"
  }

  $overwrite = Read-Host "Overwrite? (y/n)"
  if ($overwrite -ne "y") { return }
}

# Build payload
$file = New-TemporaryFile
[PSCustomObject]@{
    files = $files
} `
| ConvertTo-Json -Compress `
| Set-Content -Path $file.FullName

# Upload frames using the Python script
try {
    Write-Host "Uploading files..."
    $responses = python '.\tools\upload file\upload file.py' "$($file.FullName)"
    $success = $?
}
finally {
    Remove-Item -Path $file.FullName
}
if ($success -eq $false) {
    Write-Warning "Failed to upload files."
    return
}

# Update cached data
foreach ($line in $responses) {
    $response = $line | ConvertFrom-Json
    $filePath = $response.path
    $fileUrl = $response.url
    $fileMimetype = $response.mimetype
    $cachedFiles[$filePath] = [PSCustomObject]@{
        path        = $filePath
        url         = $fileUrl
        mimetype    = $fileMimetype
        displayname = "$filePath"
    }
}
  
# Save updated cached data
$cachedFiles | ConvertTo-Json | Set-Content -Path "files.json"
  
# Inform the user
Write-Host "Uploaded files and updated cache."
  