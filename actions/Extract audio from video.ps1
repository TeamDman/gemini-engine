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

# Function to merge all audio streams in a video file
# function Merge-AudioInVideo {
#     param(
#         [Parameter(Mandatory=$true)]
#         [string]$video
#     )
    
#     # Count the number of audio streams
#     $audioStreamCount = & ffprobe -loglevel error -select_streams a -show_entries stream=index -of csv=p=0 ".\videos\$video" | Measure-Object -Line
#     $audioStreamCount = $audioStreamCount.Lines
    
#     # Start constructing the filter_complex string
#     $filterComplex = ""
#     for ($i = 0; $i -lt $audioStreamCount; $i++) {
#         if ($i -eq 0) {
#             $filterComplex += "[0:a:$i]"
#         } else {
#             $filterComplex += "[0:a:$i]"
#         }
#     }
#     $filterComplex += "amerge=inputs=$audioStreamCount[a]"
    
#     # Destination file preparation
#     $mmp3_name = [System.IO.Path]::ChangeExtension($video, ".mp3")
#     $destPath = ".\audio\$mmp3_name"
    
#     # FFmpeg command execution
#     & ffmpeg -i ".\videos\$video" -filter_complex $filterComplex -map "a" -c:a aac -b:a 48k -vn -ac 2 "$destPath"
# }

# Merge-AudioInVideo -video $video
# Count the number of audio streams
$audioStreamCount = & ffprobe -loglevel error -select_streams a -show_entries stream=index -of csv=p=0 ".\videos\$video" | Measure-Object -Line
$audioStreamCount = $audioStreamCount.Lines

# Start constructing the filter_complex string
$filterComplex = ""
for ($i = 0; $i -lt $audioStreamCount; $i++) {
    if ($i -eq 0) {
        $filterComplex += "[0:a:$i]"
    } else {
        $filterComplex += "[0:a:$i]"
    }
}
$filterComplex += "amerge=inputs=$audioStreamCount[a]"

# Calculate destination file path
$mmp3_name = [System.IO.Path]::ChangeExtension($video, ".mp3")
$output_file = ".\audio\$mmp3_name"
$input_file = ".\videos\$video"

# # Perform audio extraction
# # ffmpeg -i ".\videos\$video" -vn "$destPath"
& ffmpeg -i $input_file -filter_complex "$filterComplex" -map "[a]" -b:a 48k -ac 2 -vn "$output_file"
