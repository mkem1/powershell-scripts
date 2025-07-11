$files = @(
    "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Login Data",
    "$env:SystemDrive\Users\*\AppData\Local\Google\Chrome\User Data\Default\Login Data",
    "$env:SystemDrive\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Login Data",
    "$env:SystemDrive\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\logins.json",
    "$env:SystemDrive\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\key3.db",
    "$env:SystemDrive\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\key4.db"
)
$found = $false
foreach ($pattern in $files) {
    if (Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue) {
        $found = $true
        break
    }
}
if ($found) {
    Write-Host "Remediation required"
    exit 1
} else {
    Write-Host "Compliant"
    exit 0
}
