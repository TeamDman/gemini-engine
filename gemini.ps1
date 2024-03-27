# gemini.ps1

# Load cached data
if (Test-Path -Path .\files.json) {
  $cachedFiles = Get-Content -Path "files.json" | ConvertFrom-Json -AsHashtable
} else {
  $cachedFiles = @{}
}
if (-not (Test-Path -Path .\prompts)) {
  New-Item -ItemType Directory -Path .\prompts | Out-Null
}
$cachedPrompts = Get-ChildItem -Path "prompts/*.txt" | Select-Object -ExpandProperty Name

while ($true) {
  $action = Get-ChildItem -Path actions `
    | Select-Object -ExpandProperty name `
    | fzf
  if ([string]::IsNullOrWhiteSpace($action)) {
    break
  }
  . ".\actions\$action"  
}
