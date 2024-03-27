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