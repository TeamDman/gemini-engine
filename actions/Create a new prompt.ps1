$promptName = Read-Host "Enter a name for the prompt (.txt gets appended)"
$promptName += ".txt"
# Open prompt file in editor
& hx prompts/$promptName
# Update cached data
$cachedPrompts += $promptName