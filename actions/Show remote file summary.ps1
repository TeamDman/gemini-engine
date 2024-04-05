# Load cached data
if (Test-Path -Path .\files.json) {
    $cachedFiles = Get-Content -Path "files.json" | ConvertFrom-Json -AsHashtable
} else {
    $cachedFiles = @{}
}

$cachedfiles.Keys `
| ForEach-Object { 
    $entry = $cachedfiles[$_]
    $name = $_
    $mimetype = $entry.mimetype    
    # format as %-20s %-20s %-20s
    "{0,-100} {1,20}" -f $name, $mimetype
} `
| fzf