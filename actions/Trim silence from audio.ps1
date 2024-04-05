# Pick the input_file
$input_file = Get-ChildItem .\audio\ `
| Select-Object -ExpandProperty Name
| fzf

if (-not $input_file) {
    Write-Host "No input_file selected. Exiting..."
    return
}

Write-Host "You chose $input_file"

# Ensure output dir exists
New-Item -ItemType Directory -Path audio -ErrorAction SilentlyContinue | Out-Null

$input_file = ".\audio\$input_file"
$output_file = [System.IO.Path]::ChangeExtension($input_file, "_trimmed.mp3")

Write-Host "Trimming $input_file into $output_file"
python ".\tools\trim silence\trim silence.py" "$input_file" "$output_file"
