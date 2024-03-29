# Ensure the output dir exists
$outdir = ".\videos\"
New-Item -ItemType Directory -Path $outdir -ErrorAction SilentlyContinue | Out-Null

# Get the URL from the user
$url = Read-Host "Enter a YouTube URL"

# Download the video
$name = yt-dlp --encoding "utf-8" --print "filename" --windows-filenames $url
$dest = Join-Path -Path $outdir -ChildPath $name
yt-dlp --windows-filenames --output $dest $url

# Add to the list of downloaded videos
("{0,-50} {1}" -f $url,$name) >> ".\downloaded_videos.txt"