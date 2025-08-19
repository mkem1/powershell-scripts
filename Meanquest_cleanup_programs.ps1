# Enhanced Software Uninstaller with Logging and Error Handling
# Log file location
$LogFile = "C:\Windows\Temp\UninstallLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Function to write to both console and log file
function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    # Write to console with color coding
    switch ($Level) {
        "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
        default { Write-Host $LogEntry }
    }
    
    # Write to log file
    Add-Content -Path $LogFile -Value $LogEntry
}

# Initialize log file
Write-LogMessage "========================================" "INFO"
Write-LogMessage "Software Uninstallation Script Started" "INFO"
Write-LogMessage "Log file: $LogFile" "INFO"
Write-LogMessage "========================================" "INFO"

# Counter for tracking operations
$TotalOperations = 0
$SuccessfulOperations = 0
$FailedOperations = 0

#region TeamViewer Uninstallation
Write-LogMessage "Starting TeamViewer uninstallation process..." "INFO"
$TotalOperations++

try {
    $Uninstallers = @(
        "C:\Program Files\TeamViewer\uninstall.exe",
        "C:\Program Files (x86)\TeamViewer\uninstall.exe"
    )

    $TeamViewerFound = $false
    foreach ($Uninstaller in $Uninstallers) {
        Write-LogMessage "Checking for uninstaller: $Uninstaller" "INFO"
        
        if (Test-Path $Uninstaller) {
            Write-LogMessage "Found TeamViewer uninstaller: $Uninstaller" "SUCCESS"
            $TeamViewerFound = $true
            
            try {
                Write-LogMessage "Executing TeamViewer uninstallation..." "INFO"
                $Process = Start-Process -FilePath $Uninstaller -ArgumentList "/S" -Wait -PassThru -ErrorAction Stop
                
                if ($Process.ExitCode -eq 0) {
                    Write-LogMessage "TeamViewer uninstallation completed successfully (Exit Code: $($Process.ExitCode))" "SUCCESS"
                    $SuccessfulOperations++
                } else {
                    Write-LogMessage "TeamViewer uninstallation completed with warnings (Exit Code: $($Process.ExitCode))" "WARNING"
                    $SuccessfulOperations++
                }
            }
            catch {
                Write-LogMessage "Error during TeamViewer uninstallation: $($_.Exception.Message)" "ERROR"
                $FailedOperations++
            }
            break
        } else {
            Write-LogMessage "TeamViewer uninstaller not found: $Uninstaller" "INFO"
        }
    }
    
    # If no executable uninstaller was found, try package-based uninstallation
    if (-not $TeamViewerFound) {
        Write-LogMessage "No executable uninstaller found, checking for TeamViewer packages..." "INFO"
        
        try {
            $TeamViewerPackages = Get-Package "*TeamViewer*" -ErrorAction SilentlyContinue
            
            if ($TeamViewerPackages) {
                foreach ($Package in $TeamViewerPackages) {
                    Write-LogMessage "Found TeamViewer package: $($Package.Name) (Version: $($Package.Version))" "SUCCESS"
                }
                $TeamViewerFound = $true
                
                Write-LogMessage "Executing TeamViewer package uninstallation..." "INFO"
                $TeamViewerPackages | Uninstall-Package -Force -ErrorAction Stop
                Write-LogMessage "TeamViewer package uninstallation completed successfully" "SUCCESS"
                $SuccessfulOperations++
            } else {
                Write-LogMessage "No TeamViewer packages found either" "INFO"
            }
        }
        catch {
            Write-LogMessage "Error during TeamViewer package uninstallation: $($_.Exception.Message)" "ERROR"
            $FailedOperations++
            $TeamViewerFound = $true # Set to true to prevent the final warning message
        }
    }
    
    if (-not $TeamViewerFound) {
        Write-LogMessage "No TeamViewer installation found on this system (checked executables and packages)" "WARNING"
        $SuccessfulOperations++
    }
}
catch {
    Write-LogMessage "Unexpected error in TeamViewer uninstallation section: $($_.Exception.Message)" "ERROR"
    $FailedOperations++
}
#endregion

#region UltraVNC Uninstallation
Write-LogMessage "Starting UltraVNC uninstallation process..." "INFO"
$TotalOperations++

try {
    $UVNCUninstaller = "C:\Program Files\uvnc bvba\UltraVNC\unins000.exe"
    Write-LogMessage "Checking for UltraVNC uninstaller: $UVNCUninstaller" "INFO"

    if (Test-Path $UVNCUninstaller) {
        Write-LogMessage "Found UltraVNC uninstaller" "SUCCESS"
        
        try {
            Write-LogMessage "Executing UltraVNC uninstallation..." "INFO"
            $Process = Start-Process -FilePath $UVNCUninstaller -ArgumentList "/VERYSILENT","/NORESTART" -Wait -PassThru -ErrorAction Stop
            
            if ($Process.ExitCode -eq 0) {
                Write-LogMessage "UltraVNC uninstallation completed successfully (Exit Code: $($Process.ExitCode))" "SUCCESS"
                $SuccessfulOperations++
            } else {
                Write-LogMessage "UltraVNC uninstallation completed with warnings (Exit Code: $($Process.ExitCode))" "WARNING"
                $SuccessfulOperations++
            }
        }
        catch {
            Write-LogMessage "Error during UltraVNC uninstallation: $($_.Exception.Message)" "ERROR"
            $FailedOperations++
        }
    } else {
        Write-LogMessage "UltraVNC uninstaller not found, application may not be installed" "WARNING"
        $SuccessfulOperations++
    }
}
catch {
    Write-LogMessage "Unexpected error in UltraVNC uninstallation section: $($_.Exception.Message)" "ERROR"
    $FailedOperations++
}
#endregion

#region FortiClient VPN Uninstallation
Write-LogMessage "Starting FortiClient VPN uninstallation process..." "INFO"
$TotalOperations++

try {
    $AppName = "FortiClient VPN"
    Write-LogMessage "Searching for $AppName in installed programs..." "INFO"

    # Get the MSI product object
    $App = Get-WmiObject Win32_Product | Where-Object { $_.Name -eq $AppName }

    if ($App) {
        Write-LogMessage "Found $AppName (Product Code: $($App.IdentifyingNumber))" "SUCCESS"
        
        try {
            Write-LogMessage "Executing FortiClient VPN uninstallation via MSI..." "INFO"
            $Process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($App.IdentifyingNumber) /quiet /norestart" -Wait -PassThru -ErrorAction Stop
            
            if ($Process.ExitCode -eq 0) {
                Write-LogMessage "FortiClient VPN uninstallation completed successfully (Exit Code: $($Process.ExitCode))" "SUCCESS"
                $SuccessfulOperations++
            } elseif ($Process.ExitCode -eq 1605) {
                Write-LogMessage "FortiClient VPN was not found or already uninstalled (Exit Code: $($Process.ExitCode))" "WARNING"
                $SuccessfulOperations++
            } else {
                Write-LogMessage "FortiClient VPN uninstallation completed with exit code: $($Process.ExitCode)" "WARNING"
                $SuccessfulOperations++
            }
        }
        catch {
            Write-LogMessage "Error during FortiClient VPN uninstallation: $($_.Exception.Message)" "ERROR"
            $FailedOperations++
        }
    } else {
        Write-LogMessage "$AppName not found in installed programs" "WARNING"
        $SuccessfulOperations++
    }
}
catch {
    Write-LogMessage "Unexpected error in FortiClient VPN uninstallation section: $($_.Exception.Message)" "ERROR"
    $FailedOperations++
}
#endregion

#region GLPI Agent Uninstallation
Write-LogMessage "Starting GLPI Agent uninstallation process..." "INFO"
$TotalOperations++

try {
    Write-LogMessage "Searching for GLPI packages..." "INFO"
    $GLPIPackages = Get-Package "*GLPI*" -ErrorAction SilentlyContinue
    
    if ($GLPIPackages) {
        foreach ($Package in $GLPIPackages) {
            Write-LogMessage "Found GLPI package: $($Package.Name) (Version: $($Package.Version))" "SUCCESS"
        }
        
        try {
            Write-LogMessage "Executing GLPI Agent uninstallation..." "INFO"
            $GLPIPackages | Uninstall-Package -Force -ErrorAction Stop
            Write-LogMessage "GLPI Agent uninstallation completed successfully" "SUCCESS"
            $SuccessfulOperations++
        }
        catch {
            Write-LogMessage "Error during GLPI Agent uninstallation: $($_.Exception.Message)" "ERROR"
            $FailedOperations++
        }
    } else {
        Write-LogMessage "No GLPI packages found on this system" "WARNING"
        $SuccessfulOperations++
    }
}
catch {
    Write-LogMessage "Unexpected error in GLPI Agent uninstallation section: $($_.Exception.Message)" "ERROR"
    $FailedOperations++
}
#endregion

#region 3CX Uninstallation
Write-LogMessage "Starting 3CX uninstallation process..." "INFO"
$TotalOperations++

try {
    # First, kill any running 3CX processes
    Write-LogMessage "Checking for running 3CX processes..." "INFO"
    $ThreeCXProcesses = Get-Process "*3CX*" -ErrorAction SilentlyContinue
    
    if ($ThreeCXProcesses) {
        foreach ($Process in $ThreeCXProcesses) {
            Write-LogMessage "Found running 3CX process: $($Process.Name) (PID: $($Process.Id))" "INFO"
        }
        
        try {
            Write-LogMessage "Terminating 3CX processes..." "INFO"
            $ThreeCXProcesses | Stop-Process -Force -ErrorAction Stop
            Write-LogMessage "All 3CX processes terminated successfully" "SUCCESS"
            
            # Wait a moment for processes to fully terminate
            Start-Sleep -Seconds 2
        }
        catch {
            Write-LogMessage "Error terminating 3CX processes: $($_.Exception.Message)" "ERROR"
            Write-LogMessage "Continuing with uninstallation attempt..." "WARNING"
        }
    } else {
        Write-LogMessage "No running 3CX processes found" "INFO"
    }
    
    Write-LogMessage "Searching for 3CX packages..." "INFO"
    $ThreeCXPackages = Get-Package "*3CX*" -ErrorAction SilentlyContinue
    
    if ($ThreeCXPackages) {
        foreach ($Package in $ThreeCXPackages) {
            Write-LogMessage "Found 3CX package: $($Package.Name) (Version: $($Package.Version))" "SUCCESS"
        }
        
        try {
            Write-LogMessage "Executing 3CX uninstallation..." "INFO"
            $ThreeCXPackages | Uninstall-Package -Force -ErrorAction Stop
            Write-LogMessage "3CX uninstallation completed successfully" "SUCCESS"
            $SuccessfulOperations++
        }
        catch {
            Write-LogMessage "Error during 3CX uninstallation: $($_.Exception.Message)" "ERROR"
            $FailedOperations++
        }
    } else {
        Write-LogMessage "No 3CX packages found on this system" "WARNING"
        $SuccessfulOperations++
    }
}
catch {
    Write-LogMessage "Unexpected error in 3CX uninstallation section: $($_.Exception.Message)" "ERROR"
    $FailedOperations++
}
#endregion

#region Final Summary
Write-LogMessage "========================================" "INFO"
Write-LogMessage "Uninstallation process completed" "INFO"
Write-LogMessage "Total operations attempted: $TotalOperations" "INFO"
Write-LogMessage "Successful operations: $SuccessfulOperations" "SUCCESS"
Write-LogMessage "Failed operations: $FailedOperations" $(if ($FailedOperations -gt 0) { "ERROR" } else { "INFO" })

if ($FailedOperations -eq 0) {
    Write-LogMessage "All operations completed successfully!" "SUCCESS"
} else {
    Write-LogMessage "Some operations failed. Please review the log for details." "ERROR"
}

Write-LogMessage "Log file saved to: $LogFile" "INFO"
Write-LogMessage "========================================" "INFO"

# Display final status
if ($FailedOperations -eq 0) {
    Write-Host "`nSUCCESS: All software uninstallation operations completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nWARNING: $FailedOperations out of $TotalOperations operations failed. Check the log file for details." -ForegroundColor Yellow
}

Write-Host "Log file location: $LogFile" -ForegroundColor Cyan
#endregion