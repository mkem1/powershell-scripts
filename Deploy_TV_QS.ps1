# Need to create .intunewin with Win32 content prep tool

$CompanyFolder = 'C:\ProgramData\Meanquest'
$ExeName       = 'Support Meanquest.exe'
$PayloadExe    = Join-Path $PSScriptRoot 'TeamViewerQS.exe'
$TargetExe     = Join-Path $CompanyFolder $ExeName

New-Item -ItemType Directory -Force -Path $CompanyFolder | Out-Null
Copy-Item -LiteralPath $PayloadExe -Destination $TargetExe -Force
