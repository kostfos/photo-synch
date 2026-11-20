#!/usr/bin/env pwsh
<#
.SYNOPSIS
List video files belonging to the authenticated user that do not have thumbnails.

.DESCRIPTION
Authenticates with the Phosyn server using JWT credentials from .user,
fetches all video items, and checks each video to determine if its thumbnail
(/images/:id/thumb) exists. Outputs the missing-thumbnail videos and retains
the authentication token in the output file for subsequent operations (such as re-analysis).

.PARAMETER OutputFile
Optional file path to save the output. If specified, results are saved to this file.

.EXAMPLE
.\list-video-nothumb.ps1

Display results in console.

.EXAMPLE
.\list-video-nothumb.ps1 -OutputFile video-nothumb-list.txt

Display results in console and save to video-nothumb-list.txt.
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
    
    # Fetch all video items using media_kind=video filter
    $allVideos = @()
    $page = 1
    $pageSize = 100
    $totalFetched = 0
    
    do {
        Add-Output "Fetching video page $page..." -ForegroundColor Gray
        
        $uri = "$baseUrl/images?media_kind=video&page=$page&page_size=$pageSize"
        $response = Invoke-WebRequest -Uri $uri -Headers @{ "Authorization" = "Bearer $token" } -Method Get -ErrorAction Stop -UseBasicParsing
        
        $data = $response.Content | ConvertFrom-Json
        
        if ($data.items.Count -eq 0) {
            break
        }
        
        $allVideos += $data.items
        $totalFetched += $data.items.Count
        
        Add-Output "  Got $($data.items.Count) videos (total fetched: $totalFetched / $($data.total))" -ForegroundColor Gray
        
        if ($totalFetched -ge $data.total) {
            break
        }
        
        $page++
    } while ($true)
    
    Add-Output ""
    Add-Output "Found $($allVideos.Count) total video files. Checking thumbnail availability..." -ForegroundColor Cyan
    
    $noThumbVideos = @()
    $checkedCount = 0
    
    foreach ($video in $allVideos) {
        $checkedCount++
        $thumbUri = "$baseUrl/images/$($video.id)/thumb"
        $hasThumb = $false
        
        try {
            $thumbRes = Invoke-WebRequest -Uri $thumbUri -Headers @{ "Authorization" = "Bearer $token" } -Method Head -ErrorAction Stop -UseBasicParsing
            if ($thumbRes.StatusCode -eq 200) {
                $hasThumb = $true
            }
        }
        catch {
            # 404 Not Found or other error means thumbnail is unavailable
            $hasThumb = $false
        }
        
        if (-not $hasThumb) {
            $noThumbVideos += $video
            Add-Output "  [NO THUMB] $($video.original_filename) ($($video.id))" -ForegroundColor Yellow
        } else {
            Add-Output "  [OK]       $($video.original_filename)" -ForegroundColor DarkGray
        }
    }
    
    Add-Output ""
    Add-Output "Found $($noThumbVideos.Count) video(s) without thumbnails (out of $($allVideos.Count) total videos)" -ForegroundColor Green
    Add-Output ""
    Add-Output "============================================================================================================================================"
    Add-Output "TYPE    | ID                                   | FILENAME                         | SIZE"
    Add-Output "--------------------------------------------------------------------------------------------------------------------------------------------"
    
    $noThumbVideos | ForEach-Object {
        $mediaType = "VIDEO "
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
    Add-Output "Re-analyze single: Invoke-WebRequest -Uri 'http://$($serverIp):8080/api/v1/images/<ID>/reanalyze-metai' -Headers @{Authorization='Bearer `$token'} -Method Post"
    Add-Output "Re-analyze all:    Invoke-WebRequest -Uri 'http://$($serverIp):8080/api/v1/images/reanalyze-metai' -Headers @{Authorization='Bearer `$token'; 'Content-Type'='application/json'} -Method Post -Body '{\"image_ids\":[\"<ID1>\",\"<ID2>\"]}'"
    Add-Output "Download video:    Invoke-WebRequest -Uri 'http://$($serverIp):8080/api/v1/images/<ID>/file' -Headers @{Authorization='Bearer `$token'} -OutFile 'video.mp4'"
    Add-Output "Delete video:      Invoke-WebRequest -Uri 'http://$($serverIp):8080/api/v1/images/<ID>' -Headers @{Authorization='Bearer `$token'} -Method Delete"
    Add-Output ""
    
    # Save to file if requested
    if ($OutputFile) {
        Write-Host "Found $($noThumbVideos.Count) video(s) without thumbnails (out of $($allVideos.Count) total videos)" -ForegroundColor Green
        $outputLines | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "Output saved to: $(Resolve-Path $OutputFile)" -ForegroundColor Cyan
    }
}
catch {
    Write-Error "Failed to authenticate or fetch videos: $($_.Exception.Message)"
    if ($_.ErrorDetails) {
        Write-Error "Server response: $($_.ErrorDetails.Message)"
    }
    exit 1
}
