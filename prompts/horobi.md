# Summary


## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\expand_backup_conversations.ps1

````powershell
$convos = Get-Content .\outputs\backup-conversations.json | ConvertFrom-Json
New-Item -ItemType Directory -Path .\outputs\conversations -ErrorAction SilentlyContinue | Out-Null
$i = 0
foreach ($convo in $convos) {
    # progress bar
    $i++
    Write-Progress -Activity "Expanding conversations" -Status "Conversations expanded: $i" -PercentComplete (($i / $convos.Count) * 100)
    $convo_id = $convo.id
    $convo | ConvertTo-Json -Depth 100 | Out-File -FilePath ".\outputs\conversations\$convo_id.json"
}

````



## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\get_backup_conversations.ps1

````powershell
. .\get_latest_backup.ps1
$found = Get-Backup

New-Item -ItemType Directory -Path "outputs" -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

$zipFilePath = $found.FullName

# Open the zip file
$zipStream = [System.IO.File]::OpenRead($zipFilePath)
$zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream)

# Iterate through each file in the zip
foreach ($entry in $zipArchive.Entries) {
    Write-Host "Entry: $($entry.FullName)"

    # If you want to perform operations on each file, you can open a stream
    # For example, to read the content of a file:
    if (!$entry.FullName.EndsWith("/")) { # This checks if the entry is a file
        if ($entry.FullName -eq "conversations.json") {
            $reader = New-Object System.IO.StreamReader($entry.Open())
            $content = $reader.ReadToEnd()
            # pretty print
            Set-Content -Path "outputs\backup-conversations.json" -Value $($content | ConvertFrom-Json | ConvertTo-Json -Depth 100)
            $reader.Close()
        }
    }
}

# Clean up
$zipArchive.Dispose()
$zipStream.Close()

````



## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\pull_convo_contents.ps1

````powershell
# ensure output dir exists
New-Item -ItemType Directory -Path .\outputs\conversations -ErrorAction SilentlyContinue | Out-Null

# get bearer token
$code = Get-Content inputs\input.txt
$auth = $code | Select-String -Pattern 'authorization' | Select-Object -First 1
$auth = $auth -replace '.*"(.*)".*', '$1'

$conversation_ids = Get-Content .\outputs\conversation-ids-to-download.txt
$i = 0
foreach ($id in $conversation_ids) {
    $i++
    Write-Progress -Activity "Downloading conversations" -Status "Conversation $i of $($conversation_ids.Count)" -PercentComplete ($i / $conversation_ids.Count * 100)
    if (Test-Path ".\outputs\conversations\$id.json") {
        Write-Host "Conversation $id already downloaded"
        continue
    }
    Write-Host "Downloading conversation $id"

    $rand = Get-Random -Minimum 1 -Maximum 5
    Start-Sleep -Seconds $rand

    $uri = "https://chat.openai.com/backend-api/conversation/$id"
    $headers = @{
        "authority"="chat.openai.com"
        "authorization" = "$auth"
    }

    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
    
    $resp = Invoke-WebRequest `
    -UseBasicParsing `
    -WebSession $session `
    -Uri $uri `
    -Headers $headers

    $data = $resp.Content | ConvertFrom-Json
    $data | ConvertTo-Json -Depth 100 | Out-File -FilePath ".\outputs\conversations\$id.json"
}

````



## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\summarize_workspace.ps1

````powershell
Write-Host "Creating output dir if not exists"
New-Item -ItemType Directory -Path "outputs" -ErrorAction SilentlyContinue

Write-Host "Clearing previous prompt file"
$outfile = "outputs\prompt.md"
Clear-Content $outfile -ErrorAction SilentlyContinue

Write-Host "Gathering"
# Capture both .ps1 files and the directory structure
$found = Get-ChildItem -Recurse | Where-Object { $_.Name.EndsWith(".ps1") }
Add-Content $outfile "Found $($found.Count) PowerShell scripts in $(Get-Location)`n"

Write-Host "Iterating"
foreach ($file in $found) {
    $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
    
    Write-Host "building prompt for $($file.Name)"
    # Use the relative path for the language specifier in markdown code blocks
    Add-Content $outfile "=====BEGIN $relativePath`n$(Get-Content $file -Raw)`n===== END $relativePath"
}

Write-Host "Summary complete. Markdown file created at $outfile"
Get-Content $outfile
````



## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\build_download_list.ps1

````powershell
# Read the contents of backup-conversations.json and conversations.json
$backupConversations = Get-Content -Raw -Path "outputs\backup-conversations.json" | ConvertFrom-Json
$conversations = Get-Content -Raw -Path "outputs\conversations.json" | ConvertFrom-Json

# Create a hashtable to store the backup conversations by ID
$backupConversationsById = @{}
$epoch = [datetime]'1970-01-01T00:00:00Z'
foreach ($conversation in $backupConversations) {
    $backupConversationsById[$conversation.id] = $epoch.AddSeconds($($backup.update_time | Sort-Object -Bottom 1))
}

# Filter conversations from conversations.json based on update_time
$newConversations = $conversations | Where-Object {
    if ($backupConversationsById.ContainsKey($_.id)) {
        return [DateTime]::Parse($_.update_time) -gt $backupConversationsById[$_.id]
    }
    else {
        return $true
    }
}

# Get the IDs of conversations from conversations.json with newer update_time
$newConversationIds = $newConversations | Sort-Object -Property update_time -Descending | Select-Object -ExpandProperty id

# Output the conversation IDs
$newConversationIds > outputs\conversation-ids-to-download.txt

````



## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\ensure_backup_on_disk.ps1

````powershell
. .\get_latest_backup.ps1
$found = Get-Backup

Write-Host "Found latest ChatGPT export from $($found.Date)"
Write-Host "Ensuring file is locally available"
if ($(attrib $found.FullName).split() -contains "O") {
    Write-Host "File is not on disk! Downloading..."
    # This sets the flag that OneDrive will detect and will actually download the file for us
    attrib +p $found.FullName
    Start-Sleep -Seconds 10
    attrib -p $found.FullName
} else {
    Write-Host "File is already on disk! Woohoo!"
}
````



## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\get_latest_backup.ps1

````powershell
function Get-Backup() {
    # Get the path to the current user's Documents folder
    $documentsPath = [System.Environment]::GetFolderPath('MyDocuments')

    # Construct the backup path
    $backup = Join-Path $documentsPath -ChildPath "Backups\openai"

    # ❯ ls $backup  
    # f7e3523a860037df03f4159667310c78871d35b9fbd3ee38766f4077efa38218-2023-11-07-04-19-49.zip
    # 'openai chatgpt download f7e3523a860037df03f4159667310c78871d35b9fbd3ee38766f4077efa38218-2023-08-11-00-12-56.zip'
    $found = Get-ChildItem $backup
    # get the latest according to the date at the end
    # we need to extract the date from the filename
    $found = $found | ForEach-Object { 
        $date = $_.Name -replace '.*-(\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2})\.zip', '$1'
        $date = [datetime]::ParseExact($date, "yyyy-MM-dd-HH-mm-ss", $null)
        $_ | Add-Member -NotePropertyName "Date" -NotePropertyValue $date -PassThru
    } | Sort-Object -Property Date -Descending | Select-Object -First 1
    return $found
}
````



## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\pull_convo_list.ps1

````powershell
$backup = Get-Content .\outputs\backup-conversations.json | ConvertFrom-Json
# Create a DateTime object for the Unix epoch
$epoch = [datetime]'1970-01-01T00:00:00Z'
# Add the number of seconds in the Unix timestamp to the epoch
$backup_date = $epoch.AddSeconds($($backup.update_time | Sort-Object -Bottom 1))

Write-Host "Latest update in the backup: $backup_date"

$code = Get-Content inputs\input.txt
# Extract `"authorization"="Bearer ..."` from the code file
$auth = $code | Select-String -Pattern 'authorization' | Select-Object -First 1
# now we have `"authorization" = "Bearer ..."` so we want the string inside the second quote pair
$auth = $auth -replace '.*"(.*)".*', '$1'

$uri = "https://chat.openai.com/backend-api/conversations?offset=0&limit=100&order=updated"
$headers = @{
  "authority"="chat.openai.com"
  "authorization" = "$auth"
}

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"

$resp = Invoke-WebRequest `
-UseBasicParsing `
-WebSession $session `
-Uri $uri `
-Headers $headers

$data = $resp.Content | ConvertFrom-Json
Write-Host "Fetched $($data.items.Count) items out of $($data.total)"
$fetched_date = $data.items.update_time | Sort-Object -Top 1
Write-Host "Oldest update: $($fetched_date)"

$results = @()

# If the oldest update is still newer than the backup, we need to fetch more
if ($fetched_date -gt $backup_date) {
  $offset = 100
  while ($fetched_date -gt $backup_date) {
    Start-Sleep -Seconds 3
    $results += $data.items
    $uri = "https://chat.openai.com/backend-api/conversations?offset=$offset&limit=100&order=updated"
    $resp = Invoke-WebRequest `
    -UseBasicParsing `
    -WebSession $session `
    -Uri $uri `
    -Headers $headers
    $data = $resp.Content | ConvertFrom-Json
    Write-Host "Received $($data.items.Count) items, apparently $($data.total) exist remotely. Total received: $($results.Count)"
    $fetched_date = $data.items.update_time | Sort-Object -Top 1
    Write-Host "Oldest update: $($fetched_date)"
    $offset += 100
  }
  $results += $data.items
} else {
  $results = $data.items
}

Write-Host "Total fetched items: $($results.Count)"
Set-Content -Path .\outputs\conversations.json -Value ($results | ConvertTo-Json -Depth 100)

````



## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\README.md

````markdown
# Horobi Transcript Utility - ChatGPT

I want to search my full chat history with ChatGPT.

Using OpenAI's GDPR export, we can get a lot of our data without hammering the API.

However, conversation updates after the export must be fetched from the website.

- [`get_latest_backup.ps1`](.\get_latest_backup.ps1) - Find the latest zip file from GDPR export
- [`get_backup_conversations.ps1`](.\get_backup_conversations.ps1) - Extract conversations.json from the zip file
- [`ensure_backup_on_disk.ps1`](.\ensure_backup_on_disk.ps1) - Helper to ensure the backup is on disk; download w/ OneDrive
- [`pull_convo_list.ps1`](.\pull_convo_list.ps1) - get the list of conversation IDs and updated timestamps
- [`build_download_list.ps1`](.\build_download_list.ps1) - retain only the IDs of conversations updated after the export
- [`pull_convo_contents.ps1`](.\pull_convo_contents.ps1) - download conversation jsons
- [`expand_backup_conversations.ps1`](.\expand_backup_conversations.ps1) - unused at this time

````



## D:\Repos\Experiments\horobi-transcript-utility\chatgpt\inputs\how-to.md

````markdown
1. Visit https://chat.openai.com/
2. Open your browser inspector network tab, look for a request like `https://chat.openai.com/backend-api/conversations?offset=0&limit=28&order=updated`
3. Copy it as powershell
4. Paste into [`input.txt`](./input.txt)

```pwsh
./pull_convo_list.ps1
./build_download_list.ps1
./pull_convo_contents.ps1
```

# Inspecting JWTs

[CyberChef](https://gchq.github.io/CyberChef/) ([GitHub](https://github.com/gchq/CyberChef)) can be ran locally, which is better than building a habit around tools jwt.io.
````





===


That is the summary of a set of scripts I made to help with the automation of archiving my conversations with chatgpt.
I am also working on a series of scripts for interacting with the Gemini 1.5 Pro API.
# Summary


## D:\Repos\ml\gemini-engine\actions\View a response in VSCode.ps1

````powershell
# Select response file
$chosenResponseFile = Get-ChildItem -Path responses -Filter "*.json" `
    | Select-Object -ExpandProperty Name `
    | Sort-Object -Descending `
    | fzf --no-sort

# Check if file was selected
if ([string]::IsNullOrEmpty($chosenResponseFile)) {
    Write-Host "No response file selected."
    return
}

# Read response data
$responseData = Get-Content -Raw -Path "responses/$chosenResponseFile" `
    | ConvertFrom-Json

# Extract the "good part"
# (Modify this logic based on the actual response structure)
$extracted = $responseData.response.candidates.content.parts.text

# Open the extracted content in VSCode
$extracted | code -

````



## D:\Repos\ml\gemini-engine\actions\Mark directories of interest.ps1

````powershell
# Check if locations.txt exists, create if not
if (!(Test-Path -Path "locations.txt")) {
    New-Item -ItemType File -Path "locations.txt" | Out-Null
}
  
## Define the mark function
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
````



## D:\Repos\ml\gemini-engine\actions\Summarize directory to clipboard.ps1

````powershell
# Prompt user to enter the directory to summarize
$starting_dir = Read-Host "Enter the directory to summarize"
if ([string]::IsNullOrWhiteSpace($starting_dir) -or -not (Test-Path $starting_dir)) {
    Write-Host "Invalid or no directory specified. Exiting..."
    return
}

# Check if the specified directory is a Git repository

$choices = Get-ChildItem -Recurse -File -Path $starting_dir | Select-Object -ExpandProperty FullName
$isGitDir = $(git -C $starting_dir rev-parse --is-inside-work-tree) -eq 'true'
if ($isGitDir) {
    $choices = $choices | Where-Object { -not (git -C $starting_dir check-ignore $_) }
}

# There is opportunity for a submenu here to present the user the current extension list and allow them to modify it considering the extensions found in the directory
$allowed_extensions = Get-Content .\summarizable_extensions.txt

# Ensure that the user is only presented files with allowed extensions
$choices = $choices | Where-Object { 
    if ($_ -match "(\.[^\.\\/:*?""<>|\r\n]+)$") {
        return $allowed_extensions -contains $matches[1] 
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

$lang_ext_lookup = Get-Content .\extension_to_markdown_fence.ini -Raw | ConvertFrom-StringData

$content = $files | ForEach-Object { 
    $path = $_
    $content = Get-Content "$path" -Raw
    $extension = [System.IO.Path]::GetExtension($path)
    $lang = $lang_ext_lookup[$extension] ?? $extension.TrimStart('.')
    return "
# $path

$('`'*4)$lang
$content
$('`'*4)

"
}
| Out-String
$content = "# Summary`n`n$content`n"
$content | Set-Clipboard
Write-Host "Copied $($files.Count) files to clipboard"


````



## D:\Repos\ml\gemini-engine\actions\Load api key from 1password vault.ps1

````powershell
$env:GEMINI_API_KEY = op read "op://Private/Google AI Studio Gemini API key/credential"
Write-Host "API Key loaded into GEMINI_API_KEY environment variable."
````



## D:\Repos\ml\gemini-engine\actions\Upload a file.ps1

````powershell
# Get user choice
$filePath = Get-ChildItem -Path files `
| ForEach-Object { $_.Name } `
| fzf

# Overwrite check
if ($cachedFiles.ContainsKey($filePath)) {
  $overwrite = Read-Host "$filePath already exists, overwrite? (y/n)"
  if ($overwrite -ne "y") { continue }
}

# Get mimetype
$fileMimetype = Get-Content .\mimetypes.txt | fzf

# Upload file
$fileUrl = python file_upload.py "files/$filePath" "$fileMimetype"
if ($? -eq $false) {
  Write-Warning "Failed to upload file."
  continue
}

# Update cached data
$cachedFiles[$filePath] = [PSCustomObject]@{
  url = $fileUrl
  mimetype = $fileMimetype
}
$cachedFiles | ConvertTo-Json | Set-Content -Path "files.json"

# Inform the user
Write-Host "Uploaded file and saved the url to the cache."

````



## D:\Repos\ml\gemini-engine\actions\Interactive mode.ps1

````powershell
while ($true) {
    $chosenFileName = $cachedFiles.Keys | fzf
    if ([string]::IsNullOrEmpty($chosenFileName)) {
        $file = [PSCustomObject]@{
            url = $null
            mimetype = $null
        }
    } else {
        $file = $cachedFiles[$chosenFileName]
    }
    $prompt = Read-Host "Prompt"
    if ([string]::IsNullOrWhiteSpace($prompt)) {
        break
    }
    $payload = [pscustomobject]@{
        prompt = $prompt
        file_url = $file.url
        file_mimetype = $file.mimetype
    }
    python inference.py $($payload | ConvertTo-Json)
    pause
}
````



## D:\Repos\ml\gemini-engine\actions\Show prompt lengths.ps1

````powershell
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
````



## D:\Repos\ml\gemini-engine\actions\Manually set API key.ps1

````powershell
# Read the secure string
Write-Host -NoNewLine "Enter the API key: "
$secureString = Read-Host -AsSecureString

# Convert SecureString to BSTR (Basic String) and then to a plain text string
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
try {
    $plainText = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
} finally {
    # Make sure to free the BSTR to prevent memory leaks
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
}

# Now you can use $plainText as a regular string
# For example, setting it as an environment variable
$ENV:GEMINI_API_KEY = $plainText

# Use the environment variable
Write-Host "Set the API key as an environment variable."
````



## D:\Repos\ml\gemini-engine\actions\Create a new prompt.ps1

````powershell
$promptName = Read-Host "Enter a name for the prompt (.txt gets appended)"
$promptName += ".txt"
# Open prompt file in editor
hx prompts/$promptName
# Update cached data
$cachedPrompts += $promptName
````



## D:\Repos\ml\gemini-engine\actions\Perform image inference.ps1

````powershell
if (-not (Test-Path Env:GEMINI_API_KEY)) {
    Write-Warning "GEMINI_API_KEY environment variable not set."
    return
}

# Select file and prompt using fzf
$chosenFileName = $cachedFiles.Keys | fzf --prompt "Select file: " --header "Cached Files"
$file = $cachedFiles[$chosenFileName]
Push-Location prompts
$env:SHELL="pwsh"
$chosenPromptName = fzf --preview "bat {}" --prompt "Select prompt: " --header "Available Prompts"
Pop-Location
# Read prompt content
$prompt = Get-Content -Raw "prompts\$chosenPromptName"
# Prepare payload and call Python script
$payload = [pscustomobject]@{
    prompt = $prompt
    file_url = $file.url
    file_mimetype = $file.mimetype
}
$file = New-TemporaryFile
$payload | ConvertTo-Json | Set-Content -Path $file.FullName
try {
    python inference.py "$($file.FullName)"
} finally {
    Remove-Item -Path $file.FullName
}
````



## D:\Repos\ml\gemini-engine\actions\Edit prompts.ps1

````powershell
$file = $cachedPrompts | fzf --prompt "Select prompt to edit: " --header "Cached Prompts"
hx "prompts\$file"
````



## D:\Repos\ml\gemini-engine\actions\Preview cached files.ps1

````powershell
$cachedfiles.Keys `
    | ForEach-Object { 
        $entry = $cachedfiles[$_]
        $name = $_
        $url = $entry.url
        $mimetype = $entry.mimetype    
        # format as %-20s %-20s %-20s
        "{0,-20} {1,-20} {2,-64}" -f $name, $mimetype, $url
    } `
    | fzf
````



## D:\Repos\ml\gemini-engine\actions\Install python dependencies.ps1

````powershell
pip install -q google-api-python-client google-generativeai
````



## D:\Repos\ml\gemini-engine\actions\Suggest directory path to clipboard.ps1

````powershell
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
````



## D:\Repos\ml\gemini-engine\actions\Perform text-only inference.ps1

````powershell
if (-not (Test-Path Env:GEMINI_API_KEY)) {
    Write-Warning "GEMINI_API_KEY environment variable not set."
    return
}

Push-Location prompts
$env:SHELL="pwsh"
$chosenPromptName = fzf --preview "bat {}" --prompt "Select prompt: " --header "Available Prompts"
Pop-Location
# Read prompt content
$prompt = Get-Content -Raw "prompts\$chosenPromptName"
# Prepare payload and call Python script
$payload = [pscustomobject]@{
    prompt = $prompt
    file_url = $file.url
    file_mimetype = $file.mimetype
}
$file = New-TemporaryFile
$payload | ConvertTo-Json | Set-Content -Path $file.FullName
try {
    python inference.py "$($file.FullName)" | code -
} finally {
    Remove-Item -Path $file.FullName
}
````



## D:\Repos\ml\gemini-engine\README.md

````markdown
<div align="center">

# Gemini Engine

<img height=400 src="https://cards.scryfall.io/large/front/2/e/2e03e05b-011b-4695-950b-98dd7643b8a0.jpg?1562636055">

Mine
[![Discord](https://img.shields.io/discord/967118679370264627.svg?colorB=7289DA&logo=data:image/png)](https://discord.gg/5mbUY3mu6m)

Google Developer Community
[![Discord](https://img.shields.io/discord/1009525727504384150.svg?colorB=7289DA&logo=data:image/png)](https://discord.gg/google-dev-community)

</div>

A collection of scripts I'm using to interact with the Gemini 1.5 Pro API.

### Dependencies

This project expects the following commands to be available for full functionality:

- `pwsh`
- `fzf`
- `hx`
- `sqlite3`
- `zoxide`
- `rg`
- `eza`

## Leaking API keys

The Google python APIs will include your API key in the error messages.

Clear your Jupyter notebook cell outputs before committing notebooks to reduce risk of leaking your API key.

## Mimetypes

Sourced from https://www.iana.org/assignments/media-types/media-types.xhtml using

```javascript
copy(Array.from(document.querySelectorAll("td:nth-child(2)")).map(x => x.innerText).join("\n"))
```
````

The horobi thing does a few things.
Because I have exported a snapshot in time using the GDPR export thing, not all the conversations must be downloaded.
We only need to download conversations that aren't included in the backup, and conversations that aren't already downloaded from previous iterations of the script.
The backup is stored in a zip in my OneDrive.
We want to be able to search the conversations, each conversation has a GUID.
By extracting the conversations from the zip file and the website, we can create a json file for each conversation.
The web interface lists the conversation change date, so we must fetch conversations, taking pages until we get to the page that contains conversations that haven't been modified since the last backup.

The scripts in the horobi-transcript-utility aren't intuitively named, and some are trying to do multiple things at once.
I want to separate them into the core concerns.
Additionally, the method of putting all the jsons in the output folder flat is not scalable.
Windows doesn't like a billion files in a flat structure, so we can group them by yyyy/mm/dd structure.
We must also consider the case of a conversation that has been download previously but has since had an update.
Let's have the yyyy/mm/dd be the date of the start of the conversation so we don't need to deal with moving if a conversation spans multiple days.

Here is an example conversation.json

```json
{
  "title": "Bevy Egui Inspector Integration",
  "create_time": 1705717139.508822,
  "update_time": 1705717177.912138,
  "moderation_results": [],
  "current_node": "debe6711-dfdd-433f-a6e0-39f4db5b0e94",
  "conversation_id": "0a1aa351-2351-4fd4-946f-7a5a8eb03bea",
  "is_archived": false,
  "safe_urls": [
    "window.name"
  ]
}
```

Let's aim for a similar structure as the gemini-engine repo.

We will have an entrypoint ps1 file that will enumerate a folder containing individual action ps1 files.

We will want the following actions:

- Set API key from request copied as powershell from browser network tools
  - read from clipboard
  - extract bearer token
  - set as environment variable
- Expand backup to conversations\yyyy\mm\dd
  - list zips in the backup folder
  - ensure file is locally available by using attrib to get onedrive to download it
  - extract the conversations
- Download conversations not present on disk yet
  - if conversations folder empty or not exist, error regarding running expand backup first
  - if bearer token env not set, error regarding running set api key first
  - get list of conversations from the website
  - identify conversations to be downloaded based on update time
  - download conversations
- Search conversations
  - use fzf and ripgrep

Please format your response as markdown, with the code blocks identifying the content of the scripts.

Here is some context on using fzf and ripgrep from their github

```md
Using fzf as interactive Ripgrep launcher
We have learned that we can bind reload action to a key (e.g. --bind=ctrl-r:execute(ps -ef)). In the next example, we are going to bind reload action to change event so that whenever the user changes the query string on fzf, reload action is triggered.

Here is a variation of the above rfv script. fzf will restart Ripgrep every time the user updates the query string on fzf. Searching and filtering is completely done by Ripgrep, and fzf merely provides the interactive interface. So we lose the "fuzziness", but the performance will be better on larger projects, and it will free up memory as you narrow down the results.

#!/usr/bin/env bash

# 1. Search for text in files using Ripgrep
# 2. Interactively restart Ripgrep with reload action
# 3. Open the file in Vim
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
INITIAL_QUERY="${*:-}"
: | fzf --ansi --disabled --query "$INITIAL_QUERY" \
    --bind "start:reload:$RG_PREFIX {q}" \
    --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
    --delimiter : \
    --preview 'bat --color=always {1} --highlight-line {2}' \
    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
    --bind 'enter:become(vim {1} +{2})'
image

Instead of starting fzf in the usual rg ... | fzf form, we start fzf with an empty input (: | fzf), then we make it start the initial Ripgrep process immediately via start:reload binding. This way, fzf owns the initial Ripgrep process so it can kill it on the next reload. Otherwise, the process will keep running in the background.
Filtering is no longer a responsibility of fzf; hence --disabled
{q} in the reload command evaluates to the query string on fzf prompt.
sleep 0.1 in the reload command is for "debouncing". This small delay will reduce the number of intermediate Ripgrep processes while we're typing in a query.
```

Let's think step by step.
Create an English outline for each action that is to be created, the steps within the action that need to be taken, and the expected outcome of the action.
Actions will have user input using Read-Host for free-text and fzf for choice from enumerable options.
Outcomes will be state changes such as setting environment variables, creating files, or modifying files.
Then, proceed with creating the implementation of the actions in the markdown code block for each ps1 file.

Include instructions for updating the horobi repository from its current state to the new state.

Thank you, I look forward to your response.
- Teamy