# Load cached data
if (Test-Path -Path .\files.json) {
  $cachedFiles = Get-Content -Path "files.json" | ConvertFrom-Json -AsHashtable
}
else {
  $cachedFiles = @{}
}

# Find images to upload
$options = Get-ChildItem -Path ".\images" `
| Select-Object -ExpandProperty Name

# Prompt user to select images
$chosen = $options | fzf `
  --multi `
  --header "Select images to upload" `
  --bind "ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all"
if (-not $chosen) {
  Write-Host "No file selected. Exiting..."
  return
}

# Prepare files
$files = @()
foreach ($file in $chosen) {
  $filePath = ".\images\$file"
  $fileMimetype = "image/" + [System.IO.Path]::GetExtension($file).TrimStart(".")
  $files += [PSCustomObject]@{
    path        = $filePath
    mimetype    = $fileMimetype
    displayname = $file
  }
}
Write-Host "Found $($files.Count) files."


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
