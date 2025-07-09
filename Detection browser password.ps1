# Detection Script: Checks for existence of browser password files

$filesToCheck = @(
    "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Login Data",
    "$env:SystemDrive\Users\*\AppData\Local\Google\Chrome\User Data\Default\Login Data",
    "$env:SystemDrive\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Login Data",
    "$env:SystemDrive\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\logins.json",
    "$env:SystemDrive\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\key3.db",
    "$env:SystemDrive\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\key4.db"
)

$found = $false

foreach ($pattern in $filesToCheck) {
    if (Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue) {
        $found = $true
        break
    }
}

if ($found) {
    # Files found, remediation needed
    Write-Output "Browser password files detected."
    exit 1
} else {
    # No files found, no remediation needed
    Write-Output "No browser password files detected."
    exit 0
}
