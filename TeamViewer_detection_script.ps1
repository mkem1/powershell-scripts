# Detection script for TeamViewer
$paths = @(
    "C:\Program Files\TeamViewer",
    "C:\Program Files (x86)\TeamViewer"
)

$found = $false
foreach ($path in $paths) {
    if (Test-Path $path) {
        $found = $true
        break
    }
}

if ($found) {
    Write-Output "TeamViewer detected."
    exit 1   # Non-zero exit = remediation needed
} else {
    Write-Output "TeamViewer not found."
    exit 0   # Zero exit = compliant
}
