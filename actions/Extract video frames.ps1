# Pick the video
$video = Get-ChildItem .\videos\ `
| Select-Object -ExpandProperty Name
| fzf

if (-not $video) {
    Write-Host "No video selected. Exiting..."
    return
}

Write-Host "You chose $video"

# Calculate destination path
$basename = [System.IO.Path]::ChangeExtension($video, "")
$out_dir = ".\video frames\$basename"
New-Item -ItemType Directory -Force -Path $out_dir -ErrorAction SilentlyContinue | Out-Null

# Extract frames using ffmpeg
ffmpeg -i ".\videos\$video" -vf "fps=1" "$out_dir\frame_%04d.png"