# construct user desktop path
# Get 'username' only (not COMPUTERNAME\username)
$user = (Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace '.*\\', ''
# Construct Desktop path
$desktop = "C:\Users\$user\Desktop"
 
####################################
 
# Uninstall NinjaRMM (other script provided)
 
# Uninstall TeamViewer (via cmd)
cmd.exe /c "cd "C:\Program Files\TeamViewer\uninstall.exe /S"" -Force -ErrorAction SilentlyContinue
cmd.exe /c "cd "C:\Program Files (x86)\TeamViewer\uninstall.exe /S"" -Force -ErrorAction SilentlyContinue

# Uninstall ultra VNC
Start-Process -FilePath "C:\Program Files\uvnc bvba\UltraVNC\unins000.exe" -ArgumentList "/VERYSILENT", "/NORESTART" -Wait -Force -ErrorAction SilentlyContinue

# Uninstall FortiClient VPN 
$AppName = "FortiClient VPN"
$App = Get-WmiObject Win32_Product | Where-Object { $_.Name -eq $AppName } -Wait -Force -ErrorAction SilentlyContinue
msiexec /uninstall $App.IdentifyingNumber /norestart /quiet -Wait -Force -ErrorAction SilentlyContinue
 
# DL Meanquest TeamViewer QS
Invoke-WebRequest -Uri "https://get.teamviewer.com/6452gdr" -OutFile "C:\tmp\TeamViewerQS.exe"
Copy-Item "C:\tmp\TeamViewerQS.exe" "C:\Users\Public\Desktop\"
 
# Remove RDS shortcut
Remove-Item "$desktop\*.rds" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Users\Public\Desktop\*.rds" -Force -ErrorAction SilentlyContinue
Remove-Item "$desktop\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*.rds" -Force -ErrorAction SilentlyContinue


# Uninstall 3CX
# Kill 3CX processes first
Get-process | Where-Object {$_.name -Like "*3CX*"} | stop-process
 
# Attempt #1 - via EXE uninstall method
$3cxapps = Get-WMIObject -Class Win32_product | where {$_.name -like "3CX Desktop APP"}
foreach ($app in $3cxapps) {
try {
$app.Uninstall()
Remove-Item C:\Users\$env:UserName\AppData\Roaming\3CXDesktopApp -Recurse
Remove-Item C:\Users\$env:UserName\AppData\Local\Programs\3CXDesktopApp -Recurse
Remove-Item C:\Users\$env:UserName\Desktop\3CX Desktop App.lnk -Recurse
Write-Host "Uninstalled $($app.Name)"
}
catch {
Write-Host "Error uninstalling $($app.Name): $($_.Exception.Message)"
}
}
 
# Attempt #2 - via MSIEXEC ~ Requires Set-ExecutionPolicy to be changed
$appInstalled = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -eq "3CX Desktop App" }
if ($appInstalled) {
try {
$uninstallString = $appInstalled.UninstallString
Start-Process msiexec.exe -ArgumentList "/x `"$uninstallString`" /qn" -Wait -NoNewWindow
Remove-Item C:\Users\$env:UserName\AppData\Roaming\3CXDesktopApp -Recurse
Remove-Item C:\Users\$env:UserName\AppData\Local\Programs\3CXDesktopApp -Recurse
Remove-Item C:\Users\$env:UserName\Desktop\3CX Desktop App.lnk -Recurse
Write-Host "Uninstalled $($appName)"
}
catch {
Write-Host "Error uninstalling $($appName): $($_.Exception.Message)"
}
}
else {
Write-Host "$appName is not installed"
}

# Attempt #3 - via CMD

cmd.exe /c "wmic product where name="3CXPhone for Windows" call uninstall /nointeractive" -Force -ErrorAction SilentlyContinue
Remove-Item C:\ProgramData\3CXPhone for Windows -Recurse