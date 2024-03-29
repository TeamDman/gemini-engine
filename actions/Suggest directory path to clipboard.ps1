$suggestions = @()
if (Get-Command sqlite3) {
    $suggestions += sqlite3 -json $Env:APPDATA\Code\User\globalStorage\state.vscdb "SELECT * FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList';" .exit `
        | ConvertFrom-Json `
        | Select-Object -ExpandProperty value `
        | ConvertFrom-Json `
        | Select-Object -ExpandProperty entries `
        | Where-Object { $_.folderUri?.StartsWith("file:///") } `
        | Select-Object -ExpandProperty folderUri `
        | ForEach-Object { [System.Uri]::UnescapeDataString($_) } `
        | ForEach-Object { $_ -replace '^file:///', '' } `
        | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1)}
} else {
    Write-Warning "sqlite3 wasn't detected"
}

if (Get-Command zoxide) {
    $suggestions += zoxide query -l
} else {
    Write-Warning "zoxide wasn't detected"
}

$psreadlinepath = "$Env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine"
if ((Test-Path $psreadlinepath) -and (Get-Command rg)) {
    $suggestions += rg "^cd [A-Za-z]:\\[^;]*" $psreadlinepath --only-matching --no-line-number --no-heading --no-filename
} else {
    Write-Warning "PSReadLine wasn't detected"
}
$old = $env:SHELL
$env:SHELL="pwsh"
try {
    $chosen = $suggestions `
        | ForEach-Object { $_ -replace '/', '\' } `
        | Sort-Object -Unique `
        | Where-Object { Test-Path $_ } `
        | fzf --prompt "Select a directory: " --preview "eza -1 --icons=always {}"
    $chosen | Set-Clipboard
    Write-Host "Directory copied to clipboard: $chosen"
} finally {
    $env:SHELL = $old
}