# Check if locations.txt exists, create if not
if (!(Test-Path -Path "locations.txt")) {
    New-Item -ItemType File -Path "locations.txt" | Out-Null
}
  
# Define the mark function
function mark {
    $currentDir = (Get-Location).Path
    Add-Content -Path "locations.txt" -Value $currentDir
    Write-Host "Marked directory: $currentDir"
}
  
# Start a subshell with the mark function available
$newShell = New-Object System.Management.Automation.Runspaces.Runspace
$newShell.Open()
$newShell.SessionStateProxy.SetVariable("mark", $function:mark)
Invoke-Expression "& { $newShell.CreatePipeline().Invoke() }"

# Close the subshell
$newShell.Close()

Write-Host "Finished marking directories."