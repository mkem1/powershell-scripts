Start-Transcript -Path 'C:\Scripts\Purge_logs_folders_by_zipping.log' -Append

$SourceFolder = "C:\Temp\Meantest"
$ZipFolder    = "C:\Temp\Meantest"
$DaysOld      = 90
$7zPath       = "C:\Program Files\7-Zip\7z.exe"  # Adjust if needed

# Ensure the archive folder exists
if (!(Test-Path $ZipFolder)) {
    New-Item -ItemType Directory -Path $ZipFolder | Out-Null
}

# Get only subfolders older than X days
$OldFolders = Get-ChildItem -Path $SourceFolder -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOld) }

if ($OldFolders) {
    foreach ($folder in $OldFolders) {
        $ZipName = "$($folder.Name)_{0}.7z" -f (Get-Date -Format "yyyyMMdd_HHmmss")
        $ZipPath = Join-Path -Path $ZipFolder -ChildPath $ZipName

        # Compress the entire folder with 7-Zip
        Start-Process -NoNewWindow -Wait -FilePath $7zPath -ArgumentList "a -t7z `"$ZipPath`" -mx=5 -md64m -mmt4 `"$($folder.FullName)`""

        # If compression succeeded, delete the original folder
        if (Test-Path $ZipPath) {
            Remove-Item -Path $folder.FullName -Recurse -Force
            Write-Host "Archived and deleted folder: $($folder.FullName) -> $ZipPath"
        } else {
            Write-Host "Compression failed for folder: $($folder.FullName)"
        }
    }
} else {
    Write-Host "No folders older than $DaysOld days found."
}
Stop-Transcript