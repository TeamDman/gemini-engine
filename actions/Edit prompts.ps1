$file = $cachedPrompts | fzf --prompt "Select prompt to edit: " --header "Cached Prompts"
hx "prompts\$file"