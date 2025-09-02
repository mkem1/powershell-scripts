Start-Transcript -Path 'C:\Scripts\Zip_Folders.log' -Append

$SourceFolder = "E:\Profile_OldTEST"  # Path containing folders to compress
$ZipFolder = "E:\Profile_OldTEST"  # Destination path for zip files
$7zPath = "C:\Program Files\7-Zip\7z.exe"  # Adjust if needed

# Ensure the zip folder exists
if (!(Test-Path $ZipFolder)) {
    New-Item -ItemType Directory -Path $ZipFolder | Out-Null
    Write-Host "Created destination folder: $ZipFolder"
}

# Check if source folder exists
if (!(Test-Path $SourceFolder)) {
    Write-Host "Error: Source folder '$SourceFolder' does not exist."
    Stop-Transcript
    exit 1
}

# Check if 7-Zip exists
if (!(Test-Path $7zPath)) {
    Write-Host "Error: 7-Zip not found at '$7zPath'. Please install 7-Zip or adjust the path."
    Stop-Transcript
    exit 1
}

# Get all folders in the source directory
$Folders = Get-ChildItem -Path $SourceFolder -Directory

if ($Folders.Count -eq 0) {
    Write-Host "No folders found in '$SourceFolder'"
    Stop-Transcript
    exit 0
}

Write-Host "Found $($Folders.Count) folder(s) to compress:"

foreach ($Folder in $Folders) {
    $FolderName = $Folder.Name
    $ZipName = "$FolderName.7z"
    $ZipPath = Join-Path -Path $ZipFolder -ChildPath $ZipName
    
    Write-Host "Compressing '$FolderName' -> '$ZipName'..."
    
    # Compress folder with 7-Zip
    $Arguments = "a -t7z `"$ZipPath`" `"$($Folder.FullName)\*`" -mx=5 -md64m -mmt4"
    
    try {
        Start-Process -NoNewWindow -Wait -FilePath $7zPath -ArgumentList $Arguments
        
        # Check if compression was successful
        if (Test-Path $ZipPath) {
            $ZipSize = (Get-Item $ZipPath).Length / 1MB
            Write-Host "✓ Successfully created '$ZipName' (Size: $([math]::Round($ZipSize, 2)) MB)"
        } else {
            Write-Host "✗ Compression failed for '$FolderName'!"
        }
    }
    catch {
        Write-Host "✗ Error compressing '$FolderName': $($_.Exception.Message)"
    }
}

Write-Host "`nCompression complete! Zip files saved to: '$ZipFolder'"

Stop-Transcript