$promptFiles = Get-ChildItem -Path "prompts" -Filter "*.txt"

# Loop through each file and calculate length
$summary = @()
foreach ($file in $promptFiles) {
  $content = Get-Content -Path $file.FullName -Raw
  $length = $content.Length
  $summary += [PSCustomObject]@{
    Name   = $file.BaseName
    Length = $length
  }
}

$summary | Format-Table -AutoSize