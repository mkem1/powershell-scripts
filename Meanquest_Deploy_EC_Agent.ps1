#************ MANAGEENGINE ENDPOINTCENTRAL AGENT INSTALLATION WITH LOGGING ************

param(
    [string]$ExeFileName = "LocalOffice_Agent.exe",
    [string]$InstallSource = "GPO"
)
$errorActionPreference = "Stop"

# Définir le chemin du fichier de log
$logFilePath = "C:\tmp\ManageEngine_InstallLog.txt"

function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFilePath -Value "$timestamp - $message"
}

Write-Log "---- Script started ----"

try {
    if([System.Environment]::Is64BitOperatingSystem) {
        $regkey = 'HKLM:SOFTWARE\Wow6432Node\AdventNet\DesktopCentral\DCAgent'
        Write-Log "64-bit architecture detected"
    } else {
        $regkey = 'HKLM:SOFTWARE\AdventNet\DesktopCentral\DCAgent'
        Write-Log "32-bit architecture detected"
    }

    if(Test-Path $regkey) {
        $agentVersion = (Get-ItemProperty $regkey).DCAgentVersion
        Write-Log "Agent version found: $agentVersion"
    } else {
        Write-Log "Agent registry key not found"
    }

    if(-not $agentVersion) {
        [string]$InstallCmd = "$PSScriptRoot\$ExeFileName -s -r -f1`"%systemroot%\temp\install.iss`" /silent INSTALLSOURCE=$InstallSource"
        Write-Log "Executing install command: $InstallCmd"

        $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $InstallCmd" -Wait -PassThru
        if ($proc.ExitCode -eq 0) {
            Write-Log "Installation command executed successfully"
        } else {
            Write-Log "Installation command exited with code $($proc.ExitCode)"
        }
    } else {
        Write-Log "Agent already installed, no installation needed"
    }
}
catch {
    Write-Log "Error: $_"
}

Write-Log "---- Script ended ----"
