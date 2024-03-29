# Get user choice
$filePath = Get-ChildItem -Path files `
| ForEach-Object { $_.Name } `
| fzf

# Overwrite check
if ($cachedFiles.ContainsKey($filePath)) {
  $overwrite = Read-Host "$filePath already exists, overwrite? (y/n)"
  if ($overwrite -ne "y") { continue }
}

# Get mimetype
$fileMimetype = Get-Content .\mimetypes.txt | fzf

# Upload file
$fileUrl = python '.\tools\upload file\upload file.py' "files/$filePath" "$fileMimetype"
if ($? -eq $false) {
  Write-Warning "Failed to upload file."
  continue
}

# Update cached data
$cachedFiles[$filePath] = [PSCustomObject]@{
  url = $fileUrl
  mimetype = $fileMimetype
}
$cachedFiles | ConvertTo-Json | Set-Content -Path "files.json"

# Inform the user
Write-Host "Uploaded file and saved the url to the cache."
