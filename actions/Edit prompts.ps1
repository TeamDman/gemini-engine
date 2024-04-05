# Get prompt files
$prompts = Get-ChildItem -Path "prompts" `
| Select-Object -ExpandProperty Name

$file = $prompts | fzf --prompt "Select prompt to edit: " --header "Cached Prompts"
& hx "prompts\$file"