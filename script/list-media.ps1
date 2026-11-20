#!/usr/bin/env pwsh
<#
.SYNOPSIS
List all images/videos belonging to the authenticated user from Phosyn server.

.DESCRIPTION
Authenticates with the Phosyn server using JWT, then fetches all media files
(paginated) and outputs them in a structured format.

.PARAMETER OutputFile
Optional file path to save the output. If specified, results are saved to this file.

.EXAMPLE
.\list-media.ps1

Display results in console.

.EXAMPLE
.\list-media.ps1 -OutputFile media-list.txt

Display results in console and save to media-list.txt.
#>

param(
    [string]$OutputFile
)

# Determine if we're saving to file (affects console output verbosity)
$savingToFile = -not [string]::IsNullOrEmpty($OutputFile)

# Collect output for file saving
$outputLines = @()

# Function to output and optionally collect
function Add-Output {
    param([string]$Text, [string]$ForegroundColor = "")
    # Only display to console if NOT saving to file (unless it's a key message)
    if (-not $Script:savingToFile) {
        if ($Text) {
            if ($ForegroundColor) {
                Write-Host $Text -ForegroundColor $ForegroundColor
            } else {
                Write-Host $Text
            }
        } else {
            Write-Host ""
        }
    }
    # Always collect for file output
    if ($Text) {
        $Script:outputLines += $Text
    } else {
        $Script:outputLines += ""
    }
}

# Read credentials from .user file
$userFilePath = Split-Path -Parent $PSCommandPath | Join-Path -ChildPath ".user"
if (-not (Test-Path $userFilePath)) {
    Write-Error "User credentials file not found at: $userFilePath"
    exit 1
}

$lines = @(Get-Content $userFilePath)
$serverIp = $lines[0].Trim()
$username = $lines[1].Trim()
$password = $lines[2].Trim()

$baseUrl = "http://$($serverIp):8080/api/v1"

Add-Output "Connecting to Phosyn server at http://$($serverIp):8080 as user '$username'..." -ForegroundColor Cyan

try {
    # Login to get JWT token
    Add-Output "Authenticating..." -ForegroundColor Gray
    $loginUrl = "$baseUrl/auth/login"
    $loginBody = @{
        username = $username
        password = $password
    } | ConvertTo-Json
    
    $loginResponse = Invoke-WebRequest -Uri $loginUrl -Method Post -ContentType "application/json" -Body $loginBody -ErrorAction Stop -UseBasicParsing
    
    $loginData = $loginResponse.Content | ConvertFrom-Json
    $token = $loginData.token
    
    Add-Output "Authenticated as $($loginData.user.username) (ID: $($loginData.user.id))" -ForegroundColor Green
    
    # Fetch all pages
    $allItems = @()
    $page = 1
    $pageSize = 100
    $totalFetched = 0
    
    do {
        Add-Output "Fetching page $page..." -ForegroundColor Gray
        
        $uri = "$baseUrl/images?page=$page&page_size=$pageSize"
        $response = Invoke-WebRequest -Uri $uri -Headers @{ "Authorization" = "Bearer $token" } -Method Get -ErrorAction Stop -UseBasicParsing
        
        $data = $response.Content | ConvertFrom-Json
        
        if ($data.items.Count -eq 0) {
            break
        }
        
        $allItems += $data.items
        $totalFetched += $data.items.Count
        
        Add-Output "  Got $($data.items.Count) items (total so far: $totalFetched / $($data.total))" -ForegroundColor Gray
        
        if ($totalFetched -ge $data.total) {
            break
        }
        
        $page++
    } while ($true)
    
    Add-Output ""
    Add-Output "Found $($allItems.Count) media files total" -ForegroundColor Green
    Add-Output ""
    Add-Output "============================================================================================================================================"
    Add-Output "TYPE    | ID                                   | FILENAME                         | SIZE"
    Add-Output "--------------------------------------------------------------------------------------------------------------------------------------------"
    
    $allItems | ForEach-Object {
        $mediaType = if ($_.mime -like "image/*") { "IMAGE " } else { "VIDEO " }
        $size = "{0:N0} bytes" -f $_.size_bytes
        $filename = if ($_.original_filename.Length -gt 32) { $_.original_filename.Substring(0, 29) + "..." } else { $_.original_filename.PadRight(32) }
        $id = $_.id
        
        Add-Output "$mediaType | $id | $filename | $size"
    }
    
    Add-Output "============================================================================================================================================"
    Add-Output ""
    Add-Output "Using these IDs for operations:" -ForegroundColor Cyan
    Add-Output ""
    Add-Output "`$token = '$token'" -ForegroundColor Gray
    Add-Output ""
    Add-Output "Download:  Invoke-WebRequest -Uri 'http://$($serverIp):8080/api/v1/images/<ID>/file' -Headers @{Authorization='Bearer `$token'} -OutFile 'file.jpg'"
    Add-Output "Details:   Invoke-WebRequest -Uri 'http://$($serverIp):8080/api/v1/images/<ID>' -Headers @{Authorization='Bearer `$token'} | ConvertFrom-Json"
    Add-Output "Delete:    Invoke-WebRequest -Uri 'http://$($serverIp):8080/api/v1/images/<ID>' -Headers @{Authorization='Bearer `$token'} -Method Delete"
    Add-Output ""
    
    # Save to file if requested
    if ($OutputFile) {
        Write-Host "Found $($allItems.Count) media files total" -ForegroundColor Green
        $outputLines | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "Output saved to: $(Resolve-Path $OutputFile)" -ForegroundColor Cyan
    }

    }
catch {
    Write-Error "Failed to authenticate or fetch images: $($_.Exception.Message)"
    if ($_.ErrorDetails) {
        Write-Error "Server response: $($_.ErrorDetails.Message)"
    }
    exit 1
}
