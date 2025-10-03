# Intune Platform Script - TeamViewer Removal

$uninstallers = @(
    "C:\Program Files\TeamViewer\uninstall.exe",
    "C:\Program Files (x86)\TeamViewer\uninstall.exe"
)

$uninstalled = $false

foreach ($uninstaller in $uninstallers) {
    if (Test-Path $uninstaller) {
        try {
            Start-Process -FilePath $uninstaller -ArgumentList "/S" -Wait -ErrorAction Stop
            Write-Output "TeamViewer uninstalled via $uninstaller"
            $uninstalled = $true
            break
        } catch {
            Write-Output "Error running $uninstaller : $($_.Exception.Message)"
        }
    }
}

# Fallback: package-based uninstall
if (-not $uninstalled) {
    try {
        $packages = Get-Package "*TeamViewer*" -ErrorAction SilentlyContinue
        if ($packages) {
            $packages | Uninstall-Package -Force -ErrorAction Stop
            Write-Output "TeamViewer uninstalled via package provider"
            $uninstalled = $true
        }
    } catch {
        Write-Output "Error uninstalling via package provider: $($_.Exception.Message)"
    }
}

if ($uninstalled) {
    Write-Output "TeamViewer successfully removed."
} else {
    Write-Output "No TeamViewer installation found."
}

exit 0
