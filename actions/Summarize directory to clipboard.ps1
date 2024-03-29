# Prompt user to enter the directory to summarize
$starting_dir = Read-Host "Enter the directory to summarize"
if ([string]::IsNullOrWhiteSpace($starting_dir) -or -not (Test-Path $starting_dir)) {
    Write-Host "Invalid or no directory specified. Exiting..."
    return
}

# Check if the specified directory is a Git repository
$choices = cargo run --manifest-path ".\tools\list unignored files\Cargo.toml" -- $starting_dir

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
    $content = Get-Content "$path" -Raw
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

