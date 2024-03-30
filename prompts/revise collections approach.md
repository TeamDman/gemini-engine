I asked a model for a guide on switching from a single-file approach to a collection-based approach.
Here is what I asked

# Summary


## .\actions\Perform text-only inference.ps1

````powershell
if (-not (Test-Path Env:GEMINI_API_KEY)) {
    Write-Warning "GEMINI_API_KEY environment variable not set."
    return
}

Push-Location prompts
$env:SHELL = "pwsh"
$chosenPromptName = fzf --preview "bat {}" --prompt "Select prompt: " --header "Available Prompts"
if ([string]::IsNullOrWhiteSpace(($chosenPromptName))) {
    Write-Warning "No prompt selected. Exiting..."
    return
}
Pop-Location

# Read prompt content
$prompt = Get-Content -Raw "prompts\$chosenPromptName"
# Prepare payload and call Python script
$payload = [pscustomobject]@{
    prompt        = $prompt
    file_url      = $file.url
    file_mimetype = $file.mimetype
}
$file = New-TemporaryFile
$payload | ConvertTo-Json | Set-Content -Path $file.FullName
try {
    python .\tools\inference\inference.py "$($file.FullName)" | code -
}
finally {
    Remove-Item -Path $file.FullName
}
````



## .\actions\Summarize directory to clipboard.ps1

````powershell
# Prompt user to enter the directory to summarize
$starting_dir = Read-Host "Enter the directory to summarize"
if ([string]::IsNullOrWhiteSpace($starting_dir) -or -not (Test-Path $starting_dir)) {
    Write-Host "Invalid or no directory specified. Exiting..."
    return
}

# Check if the specified directory is a Git repository
$choices = cargo run --manifest-path ".\tools\list unignored files\Cargo.toml" -- $starting_dir

# There is opportunity for a submenu here to present the user the current extension list and allow them to modify it considering the extensions found in the directory
$allowed_patterns = Get-Content .\summarizable_patterns.txt

# Ensure that the user is only presented files with allowed extensions
$choices = $choices | Where-Object { 
    foreach ($pattern in $allowed_patterns) {
        if ($_ -match $pattern) {
            return $true
        }
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
if ($files.Count -eq 0) {
    Write-Warning "No files picked, no action taken"
    return
}

$lang_ext_lookup = Get-Content .\extension_to_markdown_fence.ini -Raw | ConvertFrom-StringData

$content = $files | ForEach-Object { 
    $path = $_
    $content = Get-Content "$path" -Raw
    $extension = [System.IO.Path]::GetExtension($path)
    $lang = $lang_ext_lookup[$extension] ?? $extension.TrimStart('.')
    return "
## $path

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



## .\actions\Edit prompts.ps1

````powershell
$file = $cachedPrompts | fzf --prompt "Select prompt to edit: " --header "Cached Prompts"
hx "prompts\$file"
````



## .\actions\Count prompt tokens.ps1

````powershell
if (-not (Test-Path Env:GEMINI_API_KEY)) {
    Write-Warning "GEMINI_API_KEY environment variable not set."
    return
}

# Pick the prompt
Push-Location prompts
$env:SHELL="pwsh"
$prompt = fzf `
    --preview "bat {}" `
    --prompt "Select prompt: " `
    --header "Available Prompts"
Pop-Location

if ([string]::IsNullOrWhiteSpace($prompt)) {
    Write-Warning "No prompt selected. Exiting..."
    return
}

# Perform the count
Write-Host "Counting tokens in $prompt"
$count = python ".\tools\count file tokens\count file tokens.py" ".\prompts\$prompt"
Write-Host "Token count: $count"
````



## .\actions\Show prompt lengths.ps1

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



## .\actions\Download a youtube video.ps1

````powershell
# Ensure the output dir exists
$outdir = ".\videos\"
New-Item -ItemType Directory -Path $outdir -ErrorAction SilentlyContinue | Out-Null

# Get the URL from the user
$url = Read-Host "Enter a YouTube URL"

# Download the video
$name = yt-dlp --encoding "utf-8" --print "filename" --windows-filenames $url
$dest = Join-Path -Path $outdir -ChildPath $name
yt-dlp --windows-filenames --output $dest $url

# Add to the list of downloaded videos
("{0,-50} {1}" -f $url,$name) >> ".\downloaded_videos.txt"
````



## .\actions\Extract audio from video.ps1

````powershell
# Pick the video
$video = Get-ChildItem .\videos\ `
| Select-Object -ExpandProperty Name
| fzf

if (-not $video) {
    Write-Host "No video selected. Exiting..."
    return
}

Write-Host "You chose $video"

# Ensure output dir exists
New-Item -ItemType Directory -Path audio -ErrorAction SilentlyContinue | Out-Null

# Calculate destination file path
$destFileName = [System.IO.Path]::ChangeExtension($video, ".mp3")
$destPath = ".\audio\$destFileName"

# Perform audio extraction
ffmpeg -i ".\videos\$video" -vn "$destPath"
````



## .\actions\Interactive mode.ps1

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



## .\actions\Transcribe audio.ps1

````powershell
$audio = Get-ChildItem .\audio\ `
| Select-Object -ExpandProperty Name
| fzf

if (-not $audio) {
    Write-Host "No video selected. Exiting..."
    return
}

Write-Host "You chose $audio"

New-Item -ItemType Directory -Path transcriptions -ErrorAction SilentlyContinue | Out-Null
$destFileName = [System.IO.Path]::ChangeExtension($audio, ".txt")

python .\tools\transcription\transcribe.py ".\audio\$audio" > .\transcriptions\$destFileName

Write-Host "Transcription saved to .\transcriptions\$destFileName"
````



## .\actions\Upload a file.ps1

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
$fileUrl = python '.\tools\upload file\upload file.py' "files/$filePath" "$fileMimetype"
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



## .\actions\Create a new prompt.ps1

````powershell
$promptName = Read-Host "Enter a name for the prompt (.txt gets appended)"
$promptName += ".txt"
# Open prompt file in editor
hx prompts/$promptName
# Update cached data
$cachedPrompts += $promptName
````



## .\actions\Extract video frames.ps1

````powershell
# Pick the video
$video = Get-ChildItem .\videos\ `
| Select-Object -ExpandProperty Name
| fzf

if (-not $video) {
    Write-Host "No video selected. Exiting..."
    return
}

Write-Host "You chose $video"

# Calculate destination path
$basename = [System.IO.Path]::ChangeExtension($video, "")
$out_dir = ".\video frames\$basename"
New-Item -ItemType Directory -Force -Path $out_dir -ErrorAction SilentlyContinue | Out-Null

# Extract frames using ffmpeg
ffmpeg -i ".\videos\$video" -vf "fps=1" "$out_dir\frame_%04d.png"
````



## .\actions\Perform image inference.ps1

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
    python .\tools\inference\inference.py "$($file.FullName)"
} finally {
    Remove-Item -Path $file.FullName
}
````



## .\actions\Suggest directory path to clipboard.ps1

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



## .\actions\Load api key from 1password vault.ps1

````powershell
$env:GEMINI_API_KEY = op read "op://Private/Google AI Studio Gemini API key/credential"
Write-Host "API Key loaded into GEMINI_API_KEY environment variable."
````



## .\actions\Manually set API key.ps1

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



## .\actions\Preview cached files.ps1

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



## .\actions\View a response in VSCode.ps1

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



## .\actions\Install python dependencies.ps1

````powershell
pip install -q google-api-python-client google-generativeai
````



## .\actions\Mark directories of interest.ps1

````powershell
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
````



## .\tools\inference\inference.py

````py
# gemini_invoke.py
import googleapiclient.discovery
import requests
import sys
import sys
import json
from googleapiclient.discovery import build
import os

api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    raise Exception("GEMINI_API_KEY environment variable is not set.")


def invoke_gemini(payload):
    # print(payload)
    GENAI_DISCOVERY_URL = f"https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta&key={api_key}"
    discovery_docs = requests.get(GENAI_DISCOVERY_URL)
    genai_service = googleapiclient.discovery.build_from_document(
        discovery_docs.json(), developerKey=api_key
    )

    # Extract prompt and file URL from payload
    prompt = payload["prompt"]
    file_url = payload["file_url"]
    file_mimetype = payload["file_mimetype"]

    # Prepare request body
    parts = [
        {"text": prompt},
    ]
    if file_url:
        print("File url detected, including in request")
        parts.append({"file_data": {"file_uri": file_url, "mime_type": file_mimetype}})
    contents = {"contents": [{"parts": parts}]}

    # Send request and print response
    model = "models/gemini-1.5-pro-latest"
    resp = genai_service.models().generateContent(model=model, body=contents).execute()

    # Safe response to responses/n.json where n is the number of files in the responses directory
    if not os.path.exists("responses"):
        os.makedirs("responses")
    with open(f"responses/{len(os.listdir('responses'))}.json", "w", encoding="utf-8") as f:
        json.dump(
            {
                "response": resp,
                "prompt": prompt,
                "file_url": file_url,
                "file_mimetype": file_mimetype,
            },
            f,
            indent=4,
        )
    print(resp["candidates"][0]["content"]["parts"][0]["text"])


if __name__ == "__main__":
    file = sys.argv[1]
    with open(file, "r", encoding="utf-8") as f:
        payload = json.load(f)
    invoke_gemini(payload)

````



## .\tools\upload file\upload file.py

````py
# gemini_file_upload.py
import googleapiclient.discovery
import requests
import sys
from googleapiclient.http import MediaFileUpload
import mimetypes
import os

api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    raise Exception("GEMINI_API_KEY environment variable is not set.")


def upload_file(file_path, file_mimetype):
    GENAI_DISCOVERY_URL = f"https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta&key={api_key}"
    discovery_docs = requests.get(GENAI_DISCOVERY_URL)
    genai_service = googleapiclient.discovery.build_from_document(
        discovery_docs.json(), developerKey=api_key
    )

    # Prepare file upload
    media = MediaFileUpload(file_path, mimetype=file_mimetype)
    body = {"file": {"displayName": file_path.split("/")[-1]}}

    # Upload file and get URL
    create_file_response = (
        genai_service.media().upload(media_body=media, body=body).execute()
    )
    file_uri = create_file_response["file"]["uri"]

    return file_uri


if __name__ == "__main__":
    file_path = sys.argv[1]
    file_mimetype = sys.argv[2]
    file_url = upload_file(file_path, file_mimetype)
    print(file_url)

````



## .\gemini.ps1

````powershell
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
    | Sort-Object -Descending `
    | fzf --prompt "Action: " --header "Select an action to run"
  if ([string]::IsNullOrWhiteSpace($action)) {
    break
  }
  . ".\actions\$action"
  pause
}

````



## .\README.md

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

## Dependencies

This project expects the following commands to be available for full functionality:

- `pwsh`
- `fzf`
- `hx`
- `sqlite3`
- `zoxide`
- `rg`
- `eza`
- `yt-dlp`
- `cargo`
- `python`

## Using Gemini

[FAQ](https://docs.google.com/document/d/1WBVc5W6PZvgaHLV43UGSrtwHqUmofPT0K0oHuNd7GHA/edit#heading=h.j6pr32lsg1rf)

[Docs](https://ai.google.dev/api/python/google/ai/generativelanguage/GenerativeServiceClient#generate_content)

### Feedback

Visit https://aistudio.google.com/app/prompts/new_chat and use the three dots in the top right to submit feedback to Google.

### Examples

https://github.com/google-gemini/gemini-api-cookbook/tree/main/quickstarts

https://colab.research.google.com/github/google-gemini/gemini-api-cookbook/blob/main/preview/file-api/File_API.ipynb#scrollTo=IrPDYdQSKTg4

https://colab.research.google.com/github/google-gemini/gemini-api-cookbook/blob/main/preview/file-api/File_API_Video.ipynb

## Mimetypes

Sourced from https://www.iana.org/assignments/media-types/media-types.xhtml using

```javascript
copy(Array.from(document.querySelectorAll("td:nth-child(2)")).map(x => x.innerText).join("\n"))
```
````






====



That is a summary of my workspace for working with the Gemini API.
The Gemini model supports multiple image inference, but I designed my system with the idea of uploading a single file at a time
This will require modifying my image support to work against collections of images rather than single images.
There are two steps here:
- Uploading images
- Prompting with images

Each image should only need to be uploaded once.
However, at prompt time, the user should be able to mix and match what images are included in the prompt.

Technically, the file upload API isn't just for images.

I need to upload many frames from "video frames\video name here\0001.png" etc
I don't want to add noise to the uploading of images from the "images\" folder since there aren't as many as there are video frames

For now though, lets modify the "upload a file " action to be a multi-select.
It will suggest files from images/* and from "video frames\**\*"

We will also want to create a "Create a file collection" action
It should prompt the user for a name for the collection
then it should use fzf to multi prompt the user to pick the files to include
the collection will be based off the local path to the files

then we can create an "upload a collection" action
the action will upload any files in the chosen collection that aren't already uploaded.

We will then want to update the "Perform image inference" script to have the user pick which collections to upload, using multiselect to let them pick multiple collections

We will keep storing the urls in files.json
we will create file_collections.json for this new functionality

We will also want a "Add files to collection" action to let users pick multiple collections then pick from files that are not yet part of any of the collections
We will also want a "Remove files from collection" action to let users pick multiple collections and let them pick from files in any of the selected collections to remove from all the selected collections.


Let's think step by step.

Your response should be a markdown file that contains instructions for modifying this repository to reach the desired state.
You will include markdown code blocks with the new file content, and diffs of existing content to be made.

I look forward to your response, thank you!
- Teamy

====

It responded

====
## Modifying the Repository for Multi-Image Support

Here's a step-by-step guide on modifying your repository to support multi-image inference with Gemini:

**1. Modifying "Upload a file.ps1":**

**a. Multi-select files:**

- Replace the line `$filePath = Get-ChildItem -Path files | ...` with:

```powershell
$filePaths = Get-ChildItem -Path "images/*", "video frames\**\*" | Select-Object -ExpandProperty FullName | fzf --multi
```

**b. Loop through selected files:**

- Wrap the remaining logic in a loop iterating over `$filePaths`:

```powershell
foreach ($filePath in $filePaths) {
  # Overwrite check
  ...
  # Get mimetype
  ...
  # Upload file
  ...
  # Update cached data
  ...
}
```

**2. Creating "Create a file collection.ps1":**

```powershell
# Prompt for collection name
$collectionName = Read-Host "Enter a name for the collection"

# Multi-select files
$filePaths = Get-ChildItem -Path "images/*", "video frames\**\*" | Select-Object -ExpandProperty FullName | fzf --multi

# Create collection entry
$fileCollections[$collectionName] = $filePaths

# Save collections data
$fileCollections | ConvertTo-Json | Set-Content -Path "file_collections.json"
```

**3. Creating "Upload a collection.ps1":**

```powershell
# Select collection
$collectionName = $fileCollections.Keys | fzf

# Get file paths
$filePaths = $fileCollections[$collectionName]

# Upload each file not already in cachedFiles
foreach ($filePath in $filePaths) {
  if (-not $cachedFiles.ContainsKey($filePath)) {
    # Get mimetype
    ...
    # Upload file
    ...
    # Update cached data
    ...
  }
}
```

**4. Modifying "Perform image inference.ps1":**

**a. Multi-select collections:**

- Replace the line `$chosenFileName = $cachedFiles.Keys | ...` with:

```powershell
$chosenCollectionNames = $fileCollections.Keys | fzf --multi --prompt "Select collections: "
```

**b. Loop through selected collections and files:**

- Replace the logic for selecting a single file with:

```powershell
foreach ($collectionName in $chosenCollectionNames) {
  $filePaths = $fileCollections[$collectionName]
  foreach ($filePath in $filePaths) {
    $file = $cachedFiles[$filePath]
    ...
    # Prepare payload and call Python script
    ...
  }
}
```

**5. Creating "Add files to collection.ps1":**

```powershell
# Select collections
$collectionNames = $fileCollections.Keys | fzf --multi

# Get existing files in selected collections
$existingFiles = @()
foreach ($collectionName in $collectionNames) {
  $existingFiles += $fileCollections[$collectionName]
}

# Select files not in existingFiles
$filePaths = Get-ChildItem -Path "images/*", "video frames\**\*" | Select-Object -ExpandProperty FullName | Where-Object { $existingFiles -notcontains $_ } | fzf --multi

# Add selected files to each collection
foreach ($collectionName in $collectionNames) {
  $fileCollections[$collectionName] += $filePaths
}

# Save collections data
$fileCollections | ConvertTo-Json | Set-Content -Path "file_collections.json"
```

**6. Creating "Remove files from collection.ps1":**

```powershell
# Select collections
$collectionNames = $fileCollections.Keys | fzf --multi

# Get files in selected collections
$files = @()
foreach ($collectionName in $collectionNames) {
  $files += $fileCollections[$collectionName]
}

# Select files to remove
$filePathsToRemove = $files | fzf --multi

# Remove selected files from each collection
foreach ($collectionName in $collectionNames) {
  $fileCollections[$collectionName] = $fileCollections[$collectionName] | Where-Object { $filePathsToRemove -notcontains $_ }
}

# Save collections data
$fileCollections | ConvertTo-Json | Set-Content -Path "file_collections.json"
```

**Note:** These are just the basic steps. You might need to adjust the logic and error handling based on your specific needs and preferences. 

Remember to update the main `gemini.ps1` script to include the new actions and ensure proper flow between them.
====

Given the expansion of the project, I don't think it makes sense to have global state in the gemini.ps1 file for the cached files and prompts.

The individual actions should be responsible for querying the json and prompts directory as needed.

Please review the response from the other model and propose a similar but improved plan of action for improving the repo.

The new plan should include the following phases:

1. Updating existing files to remove reliance on $cachedFiles and $cachedPrompts and instead query them as needed in actions that relied on them.
   1. This should not be a simple move-the-variable-to-the-other-files, you should revamp the files to read naturally without the global state.
2. Ensure all files under prompts/ are valid, not just .txt files
3. Modify existing files and create new files to implement support for the file collections pattern.

I look forward to your response.

Please think step by step.
There will be many steps involved in this process, do not try to do everything at once. Please include simple step instructions to be followed to upgrade the repository to the state that includes the new functionality.


Your response should be a markdown file that contains instructions for modifying this repository to reach the desired state.
You will include markdown code blocks with the new file content, and diffs of existing content to be made.

I want you to, at the start, create an English description of the changes to be made. This will help guide you as you continue the response with the implementation details. Be precise and clear in your description.

After reading your response and following its instructions, the repository should be in a working state with the new functionality.
ABSOLUTELY DO NOT leave any stub instructions such as "# then use the new variable here" or "# implement the new functionality here". Every step should be clear, actionable, and complete.

Your response should be approximately 8000 TOKENS in length.
You have enough room for more than 30 individual steps, so take your time to break down the process into manageable parts.

Thank you for your help!
I look forward to your response.
-Teamy