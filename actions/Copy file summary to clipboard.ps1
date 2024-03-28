$choices = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName

$files = @()
while ($true) {
    $chosen = $choices | fzf --multi --bind "ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all" --header "Selection will repeat until Ctrl+C received"
    if ($null -eq $chosen) {
        break
    }
    $files += $chosen
}
$content = $files | ForEach-Object { 
    $content = Get-Content $_ -Raw
    return "
#REGION $($_)
$content
#ENDREGION
"
}
| Out-String
$content | Set-Clipboard
Write-Host "Copied $($files.Count) files to clipboard"