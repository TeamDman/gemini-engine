param (
    [string]$StartingDir
)

# If no StartingDir parameter is provided or it is null/empty, prompt the user
if (-not $StartingDir -or [string]::IsNullOrWhiteSpace($StartingDir)) {
    $StartingDir = Read-Host "Enter the directory to summarize"
}

# Validate the provided directory
if ([string]::IsNullOrWhiteSpace($StartingDir) -or -not (Test-Path $StartingDir)) {
    Write-Host "Invalid or no directory specified. Exiting..."
    return
}

Write-Host "Processing directory: $StartingDir"
# Add your directory summarization logic here

# Check if the specified directory is a Git repository
$exePath = ".\target\release\list_unignored_files.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "Building list_unignored_files.exe..."
    cargo build --manifest-path ".\tools\list unignored files\Cargo.toml" --release
}
if (Test-Path $exePath) {
    $choices = & $exePath $StartingDir
} else {
    Write-Host "Failed to build list_unignored_files.exe, falling back to cargo run..."
    $choices = cargo run --manifest-path ".\tools\list unignored files\Cargo.toml" -- $StartingDir
}

# Load ignore patterns
$ignore_patterns = Get-Content .\ignore_patterns.txt
if ($? -eq $false) {
    Write-Warning "No ignore patterns found. Continuing without any ignore patterns"
    Pause
    $ignore_patterns = @()
}

# Apply ignore patterns
$choices = $choices | Where-Object { 
    $file = $_
    $ignore = $false
    foreach ($pattern in $ignore_patterns) {
        if ($file -match $pattern) {
            $ignore = $true
            break
        }
    }
    -not $ignore
}

# There is opportunity for a submenu here to present the user the current extension list and allow them to modify it considering the extensions found in the directory
$allowed_patterns = Get-Content .\summarizable_patterns.txt

# Ensure that the user is only presented files with allowed extensions
$choices = $choices | Where-Object { 
    foreach ($pattern in $allowed_patterns) {
        if ($_ -match $pattern) {
            return $true
        }
    }
    return $false
}

# Prompt the user to select files to summarize
$files = @()
while ($true) {
    $chosen = $choices | fzf --multi --bind "ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all" --header "Selection will repeat until Ctrl+C received"
    if ($null -eq $chosen) {
        break
    }
    $files += $chosen
}
if ($files.Count -eq 0) {
    Write-Warning "No files picked, no action taken"
    return
}

$lang_ext_lookup = Get-Content .\extension_to_markdown_fence.ini -Raw | ConvertFrom-StringData

$content = $files | ForEach-Object { 
    $path = $_
    $content = Get-Content -LiteralPath "$path" -Raw
    $extension = [System.IO.Path]::GetExtension($path)
    $lang = $lang_ext_lookup[$extension] ?? $extension.TrimStart('.')
    return "
## $path

$('`'*4)$lang
$content
$('`'*4)

"
}
| Out-String
$content = "# Summary`n`n$content`n"
$content | Set-Clipboard
Write-Host "Copied $($files.Count) files to clipboard"

