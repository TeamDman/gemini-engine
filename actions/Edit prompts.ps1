# Get prompt files
$prompts = Get-ChildItem -Path "prompts"

$file = $prompts | fzf --prompt "Select prompt to edit: " --header "Cached Prompts"
hx "prompts\$file"