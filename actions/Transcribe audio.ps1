$audio = Get-ChildItem .\audio\ `
| Select-Object -ExpandProperty Name
| fzf

if (-not $audio) {
    Write-Host "No video selected. Exiting..."
    return
}

Write-Host "You chose $audio"

New-Item -ItemType Directory -Path transcriptions -ErrorAction SilentlyContinue | Out-Null

python .\python\transcription\transcribe.py "$audio"