# Pick the video
$video = Get-ChildItem .\videos\ `
| Select-Object -ExpandProperty Name
| fzf

if (-not $video) {
    Write-Host "No video selected. Exiting..."
    return
}

Write-Host "You chose $video"

# Ensure output dir exists
New-Item -ItemType Directory -Path audio -ErrorAction SilentlyContinue | Out-Null

# Calculate destination file path
$destFileName = [System.IO.Path]::ChangeExtension($video, ".mp3")
$destPath = ".\audio\$destFileName"

# Perform audio extraction
ffmpeg -i ".\videos\$video" -vn "$destPath"