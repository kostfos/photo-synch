#!/usr/bin/env pwsh
<#
.SYNOPSIS
Find duplicate images/videos by filename and filesize.

.DESCRIPTION
Reads the output from list-media.ps1 and identifies duplicates (same filename and size).
For each set of duplicates, lists all but one (keeping the first occurrence).
Saves results with the JWT token to duplicates-list.txt for use by a delete script.

.PARAMETER InputFile
The output file from list-media.ps1 (required)

.PARAMETER OutputFile
Where to save the duplicates list (default: duplicates-list.txt)

.EXAMPLE
.\list-media.ps1 -OutputFile media-list.txt
.\find-duplicates.ps1 -InputFile media-list.txt

Finds duplicates in media-list.txt and saves to duplicates-list.txt with token.

.EXAMPLE
.\find-duplicates.ps1 -InputFile C:\Reports\media-list.txt -OutputFile C:\Reports\duplicates.txt
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [string]$OutputFile = "duplicates-list.txt"
)

try {
    # Verify input file exists
    if (-not (Test-Path $InputFile)) {
        Write-Error "Input file not found: $InputFile"
        exit 1
    }
    
    Write-Host "Reading $InputFile..." -ForegroundColor Cyan
    $content = Get-Content $InputFile -Raw
    
    # Extract token from file (line format: $token = 'eyJ0eXAi...')
    $tokenMatch = [regex]::Match($content, "\`$token = '([^']+)'")
    $token = if ($tokenMatch.Success) { $tokenMatch.Groups[1].Value } else { "" }
    
    if (-not $token) {
        Write-Warning "Could not extract token from input file"
    }
    
    # Parse the media table lines
    # Format: TYPE | ID | FILENAME | SIZE
    $lines = Get-Content $InputFile
    $mediaList = @()
    
    foreach ($line in $lines) {
        # Skip header and separator lines
        if ($line -match '^\s*$' -or $line -match '^====' -or $line -match '---' -or $line -match 'TYPE.*FILENAME.*SIZE') {
            continue
        }
        
        # Match lines with media data (must contain | and TYPE)
        if ($line -match '\|' -and ($line -match 'IMAGE' -or $line -match 'VIDEO')) {
            $parts = $line -split '\|'
            if ($parts.Count -eq 4) {
                $mediaList += @{
                    Type = $parts[0].Trim()
                    ID = $parts[1].Trim()
                    Filename = $parts[2].Trim()
                    Size = $parts[3].Trim()
                }
            }
        }
    }
    
    Write-Host "Found $($mediaList.Count) total media files" -ForegroundColor Green
    
    # Find duplicates by grouping on (Filename, Size)
    $grouped = $mediaList | Group-Object { "$($_.Filename)|$($_.Size)" }
    
    # Collect duplicates (all but first in each group with >1 item)
    $duplicates = @()
    foreach ($group in $grouped) {
        if ($group.Count -gt 1) {
            Write-Host "  Found $($group.Count) copies of: $($group.Name)" -ForegroundColor Yellow
            # Add all but the first (keep one, mark rest for deletion)
            $duplicates += $group.Group | Select-Object -Skip 1
        }
    }
    
    Write-Host ""
    Write-Host "Total duplicates to remove: $($duplicates.Count)" -ForegroundColor Green
    
    # Build output
    $outputLines = @()
    $outputLines += "Duplicate Files for Deletion"
    $outputLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $outputLines += ""
    $outputLines += "Token:"
    $outputLines += "`$token = '$token'"
    $outputLines += ""
    $outputLines += "Files to Delete ($($duplicates.Count) duplicates):"
    $outputLines += "============================================================================================================================================"
    $outputLines += "TYPE    | ID                                   | FILENAME                         | SIZE"
    $outputLines += "--------------------------------------------------------------------------------------------------------------------------------------------"
    
    foreach ($dup in $duplicates) {
        $outputLines += "$($dup.Type) | $($dup.ID) | $($dup.Filename) | $($dup.Size)"
    }
    
    $outputLines += "============================================================================================================================================"
    $outputLines += ""
    $outputLines += "Usage: Run the delete-duplicates.ps1 script with this file to remove these duplicates."
    
    # Save to output file
    $outputLines | Out-File -FilePath $OutputFile -Encoding UTF8
    
    Write-Host ""
    Write-Host "Results saved to: $(Resolve-Path $OutputFile)" -ForegroundColor Cyan
}
catch {
    Write-Error "Error processing duplicates: $($_.Exception.Message)"
    exit 1
}
