# How to simple
List images/videos from server<br>
Find duplicates to remove<br>
Generate thumbnails in videos<br>

# Prerequisites
Change credentials in .user file; that your scripts will act on to fetch from server<br>
Make sure powershell scripts are allowed to run:<br>
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Workflow to find delete duplicates 

## Step 1: Generate media list
.\list-media.ps1 -OutputFile media-list.txt<br>
It will list all pictures and videos<br>

## Step 2: Find duplicates
.\find-duplicates.ps1 -InputFile media-list.txt

## Step 3: Review the duplicates if found any (optional)
type duplicates-list.txt

## Step 4: Delete the duplicates (with confirmation)
.\delete-duplicates.ps1<br>
Only the duplicate ones are deleted; you keep one if it has many duplicates. <br>

## Step 5: Check the report
type deletion-report-*.txt

# Workflow to generate thumbnails

## Step 1: Generate list of videos having no thumbnails
.\list-video-nothumb.ps1 -OutputFile video-nothumb-list.txt

## Step 2: Generate thumbnails
.\generate-video-thumbs.ps1 -InputFile video-nothumb-list.txt<br>
It may take some time to generate if there are may videos; you can list again to check