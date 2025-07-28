Start-Transcript -Path 'C:\Scripts\Purge_logs_files_by_zipping.log' -Append

$SourceFolder = "C:\Program Files\DialogMaster\Log"
$ZipFolder = "C:\Program Files\DialogMaster\Log"
$DaysOld = 7
$7zPath = "C:\Program Files\7-Zip\7z.exe"  # Adjust if needed

# Ensure the zip folder exists
if (!(Test-Path $ZipFolder)) {
    New-Item -ItemType Directory -Path $ZipFolder | Out-Null
}

# Get files older than X days
$OldFiles = Get-ChildItem -Path $SourceFolder -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOld) }

if ($OldFiles) {
    $ZipName = "Archive_{0}.7z" -f (Get-Date -Format "yyyyMMdd_HHmmss")
    $ZipPath = Join-Path -Path $ZipFolder -ChildPath $ZipName
    
    # Compress with 7-Zip
    $FileList = $OldFiles.FullName -join "`r`n"
    $FileListPath = "$env:TEMP\filelist.txt"
    $FileList | Out-File -Encoding ASCII -FilePath $FileListPath
    
    Start-Process -NoNewWindow -Wait -FilePath $7zPath -ArgumentList "a -t7z `"$ZipPath`" -mx=5 -md64m -mmt4 @`"$FileListPath`""
    
    # Remove original files if compression was successful
    if (Test-Path $ZipPath) {
        $OldFiles | Remove-Item -Force
        Write-Host "Archived and deleted $($OldFiles.Count) files: $ZipPath"
    } else {
        Write-Host "Compression failed!"
    }
    
    Remove-Item -Path $FileListPath -Force
} else {
    Write-Host "No files older than $DaysOld days found."
}
Stop-Transcript