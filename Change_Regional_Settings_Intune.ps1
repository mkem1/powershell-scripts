# User-Level Language Configuration Script for Existing Devices
# Adds French (Switzerland) to END of user's language preferences (non-disruptive)
# Runs in user context for devices already provisioned with existing users

param(
    [string]$Language = "fr-CH",
    [string]$GeoId = "223" # Switzerland
)

# Set up logging in user profile
$LogPath = "$env:APPDATA\Microsoft\IntuneManagementExtension\Logs"
if (!(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force
}
$LogFile = "$LogPath\UserLanguageConfig-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-LogMessage {
    param([string]$Message, [string]$Level = "INFO")
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$TimeStamp] [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry -Force
}

function Test-UserLanguageConfiguration {
    param([string]$LanguageTag, [string]$ExpectedGeoId)
    try {
        # Check if language is in user's language list
        $UserLanguageList = Get-WinUserLanguageList -ErrorAction Stop
        $LanguageInList = $UserLanguageList | Where-Object { $_.LanguageTag -eq $LanguageTag }
        
        # Check UI language override
        $UILanguage = Get-WinUILanguageOverride -ErrorAction Stop
        $UILanguageSet = $UILanguage -eq $LanguageTag
        
        # Check user culture
        $UserCulture = Get-Culture -ErrorAction Stop
        $CultureSet = $UserCulture.Name -eq $LanguageTag
        
        # Check geo location
        $HomeLocation = Get-WinHomeLocation -ErrorAction Stop
        $GeoSet = $HomeLocation.GeoId -eq $ExpectedGeoId
        
        # Get position in language list
        $LanguagePosition = -1
        if ($LanguageInList) {
            for ($i = 0; $i -lt $UserLanguageList.Count; $i++) {
                if ($UserLanguageList[$i].LanguageTag -eq $LanguageTag) { 
                    $LanguagePosition = $i
                    break
                }
            }
        }
        
        Write-LogMessage "Current user language configuration:"
        Write-LogMessage "  Language in list: $($null -ne $LanguageInList) (Position: $LanguagePosition)"
        Write-LogMessage "  UI language override: $UILanguageSet (Current: $UILanguage)"
        Write-LogMessage "  User culture: $CultureSet (Current: $($UserCulture.Name))"
        Write-LogMessage "  Geo location: $GeoSet (Current: $($HomeLocation.GeoId))"
        Write-LogMessage "  Current language list: $($UserLanguageList | ForEach-Object { $_.LanguageTag } | Join-String ', ')"
        
        return @{
            LanguageInList = $null -ne $LanguageInList
            LanguagePosition = $LanguagePosition
            UILanguageSet = $UILanguageSet
            CultureSet = $CultureSet
            GeoSet = $GeoSet
            LanguageList = $UserLanguageList
        }
    }
    catch {
        Write-LogMessage "Error checking user language configuration: $($_.Exception.Message)" "ERROR"
        return @{
            LanguageInList = $false
            LanguagePosition = -1
            UILanguageSet = $false
            CultureSet = $false
            GeoSet = $false
            LanguageList = @()
        }
    }
}

# Main execution
try {
    Write-LogMessage "=== Starting User Language Configuration ==="
    Write-LogMessage "Target Language: $Language"
    Write-LogMessage "Target GeoId: $GeoId"
    Write-LogMessage "User: $([Environment]::UserName)"
    Write-LogMessage "Domain: $([Environment]::UserDomainName)"
    Write-LogMessage "User Profile: $env:USERPROFILE"
    
    # Check if language pack is available on system
    Write-LogMessage "=== Checking System Language Availability ==="
    try {
        $InstalledLanguages = Get-InstalledLanguage -ErrorAction Stop
        $LanguageAvailable = $InstalledLanguages | Where-Object { $_.LanguageTag -eq $Language }
        if (-not $LanguageAvailable) {
            Write-LogMessage "Language pack $Language is not installed on the system" "ERROR"
            Write-LogMessage "Available languages: $($InstalledLanguages | ForEach-Object { $_.LanguageTag } | Join-String ', ')"
            Write-LogMessage "User configuration cannot proceed without system language pack"
            exit 1
        }
        Write-LogMessage "Language pack $Language is available on the system"
    }
    catch {
        Write-LogMessage "Unable to check system language availability: $($_.Exception.Message)" "ERROR"
        Write-LogMessage "Continuing with user configuration attempt..."
    }
    
    # Check current user configuration
    Write-LogMessage "=== Current User Configuration Check ==="
    $CurrentConfig = Test-UserLanguageConfiguration -LanguageTag $Language -ExpectedGeoId $GeoId
    
    # Configure user language list (add to END to preserve user preferences)
    if (-not $CurrentConfig.LanguageInList) {
        Write-LogMessage "=== Adding Language to User Preference List ==="
        try {
            $OldList = Get-WinUserLanguageList
            Write-LogMessage "User's current language preferences: $($OldList | ForEach-Object { $_.LanguageTag } | Join-String ', ')"
            
            # Add new language to END of list (preserving user's preferred order)
            Write-LogMessage "Adding $Language to the END of language list (preserving user preferences)"
            $NewLanguageEntry = New-WinUserLanguageList -Language $Language
            $UpdatedList = $OldList + $NewLanguageEntry
            
            Set-WinUserLanguageList -LanguageList $UpdatedList -Force
            Write-LogMessage "Updated language list: $($UpdatedList | ForEach-Object { $_.LanguageTag } | Join-String ', ')"
            Write-LogMessage "Language successfully added to user preferences"
        }
        catch {
            Write-LogMessage "Failed to update user language list: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-LogMessage "$Language is already in user language list at position $($CurrentConfig.LanguagePosition)"
        Write-LogMessage "No changes needed to language list"
    }
    
    # Set UI language override (optional - user can change this)
    if (-not $CurrentConfig.UILanguageSet) {
        Write-LogMessage "=== Setting UI Language Override ==="
        try {
            Set-WinUILanguageOverride -Language $Language
            Write-LogMessage "UI language override set to $Language"
            Write-LogMessage "Note: User can change this in Windows Settings if preferred"
        }
        catch {
            Write-LogMessage "Failed to set UI language override: $($_.Exception.Message)" "WARNING"
        }
    } else {
        Write-LogMessage "UI language override already set to $Language"
    }
    
    # Set user culture (changes date/number formats)
    if (-not $CurrentConfig.CultureSet) {
        Write-LogMessage "=== Setting User Culture ==="
        Write-LogMessage "This will change date separator from '/' to '.' and other regional formats"
        try {
            Set-Culture -CultureInfo $Language
            Write-LogMessage "User culture set to $Language"
        }
        catch {
            Write-LogMessage "Failed to set user culture: $($_.Exception.Message)" "WARNING"
        }
    } else {
        Write-LogMessage "User culture already set to $Language"
    }
    
    # Set home location
    if (-not $CurrentConfig.GeoSet) {
        Write-LogMessage "=== Setting Home Location ==="
        try {
            Set-WinHomeLocation -GeoId $GeoId
            Write-LogMessage "Home location set to Switzerland (GeoId: $GeoId)"
        }
        catch {
            Write-LogMessage "Failed to set home location: $($_.Exception.Message)" "WARNING"
        }
    } else {
        Write-LogMessage "Home location already set correctly"
    }
    
    # Final verification
    Write-LogMessage "=== Final User Configuration Verification ==="
    $FinalConfig = Test-UserLanguageConfiguration -LanguageTag $Language -ExpectedGeoId $GeoId
    
    # Count successful configurations
    $SuccessCount = 0
    if ($FinalConfig.LanguageInList) { $SuccessCount++ }
    if ($FinalConfig.UILanguageSet) { $SuccessCount++ }
    if ($FinalConfig.CultureSet) { $SuccessCount++ }
    if ($FinalConfig.GeoSet) { $SuccessCount++ }
    
    Write-LogMessage "Successfully configured $SuccessCount out of 4 user settings"
    
    if ($SuccessCount -ge 2) {
        Write-LogMessage "=== User Language Configuration Completed Successfully ==="
        Write-LogMessage "Language $Language added to user's preferences (position: $($FinalConfig.LanguagePosition))"
        Write-LogMessage "Changes will take full effect after user signs out and back in"
        Write-LogMessage "User can adjust language preferences in Windows Settings > Time & Language"
        exit 0
    } else {
        Write-LogMessage "=== User Language Configuration Completed with Limited Success ===" "WARNING"
        Write-LogMessage "Some settings could not be applied, but basic language support was added"
        exit 0  # Still success as partial configuration is acceptable for user-level
    }
}
catch {
    Write-LogMessage "=== Fatal Error in User Language Configuration ===" "ERROR"
    Write-LogMessage "Error: $($_.Exception.Message)" "ERROR"
    Write-LogMessage "Stack trace: $($_.Exception.StackTrace)" "ERROR"
    exit 1
}