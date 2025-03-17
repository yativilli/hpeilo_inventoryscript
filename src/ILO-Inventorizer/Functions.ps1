. .\ILO-Inventorizer\Constants.ps1

Function Show-Help {
    param(
        [Parameter()]
        [string]
        $helpString
    )
    if ($helpString.Length -gt 0) {

        if (($helpString -eq "/?") -or ($helpString -eq "-h") -or ($helpString -eq "--help") -or ($helpString -eq "--h")) {
            Log 5 "User has requested help -displaying Help-Page"
            return $true;
        }
        else { return $false; }
    }
    else { return $false; }
}

Function New-Config {
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $Path,
        
        [Parameter()]
        [switch]
        $NotEmpty,
        
        [Parameter()]
        [switch]
        $WithOutInventory
    )
    try {
        Log 5 "Started generating new Configuration - intitalising empty object."
        $config_path = ($Path + "\config.json");
        $login_config_path = ($Path + "\login.json");
        $config = [ordered]@{
            searchForFilesAt                = $Path
            configPath                      = $config_path
            loginConfigPath                 = $login_config_path
            reportPath                      = ""
            serverPath                      = ""
            logPath                         = ""
            logLevel                        = ""
            loggingActived                  = ""
            searchStringInventory           = ""
            doNotSearchInventory            = $false
            remoteMgmntField                = ""
            deactivateCertificateValidation = $false
            logToConsole                    = $false
            ignoreMACAddress                = $false
            ignoreSerialNumbers             = $false
        };
    
        $login = [ordered]@{
            Username = ""
            Password = ""
        };

        Register-Directory $Path -ignoreError
        
        ## Generate Dummy (w/o Inventory)
        if ($NotEmpty -and $WithOutInventory) {
            Log 6 "Filling empty config w/o Inventory - generating supplementary 'server.json'"
            $config.reportPath = $Path + "\reports";
            $config.serverPath = $Path + "\servers.json";
            $config.logPath = $Path + "\logs";
            $config.logLevel = 0;
            $config.loggingActived = $true;
            $config.logToConsole = $true;
            $config.searchStringInventory = "";
            $config.doNotSearchInventory = $true;
            $config.remoteMgmntField = "";
            $config.deactivateCertificateValidation = $true;

            $login.Username = "SomeFancyUsername";
            $login.Password = "SomeFancyPassword";

            $servers = @("rmgfa-sioc-cs-dev", "rmgfa-sioc-cs-de3", "rmgfa-sioc-de4", "rmdl20test");

            $servers | ConvertTo-Json -Depth 2 | Out-File -FilePath ($Path + "\server.json");
        }
        ## Generate Dummy (w/ Inventory)
        elseif ($NotEmpty) {
            Log 6 "Filling empty config w/ Inventory"   
            $config.reportPath = $Path + "\reports";
            $config.serverPath = "";
            $config.logPath = $Path + "\logs";
            $config.logLevel = 0;
            $config.logToConsole = $true;
            $config.searchStringInventory = "rmgfa-sioc-cs";
            $config.doNotSearchInventory = $false;
            $config.remoteMgmntField = "Hostname Mgnt";
            $config.deactivateCertificateValidation = $true;

            $login.Username = "SomeFancyUsername";
            $login.Password = "SomeFancyPassword";
        }
        ## Generate empty
        else {
            Log 6 "Filling empty config with no contents"
            $config.reportPath = "";
            $config.serverPath = "";
            $config.logPath = "";
            $config.logLevel = 0;
            $config.loggingActived = $null;
            $config.logToConsole = $null;
            $config.searchStringInventory = "";
            $config.doNotSearchInventory = $null;
            $config.remoteMgmntField = "";
            $config.deactivateCertificateValidation = $null;
            $config.ignoreMACAddress = $null;
            $config.ignoreSerialNumbers = $null;

            $login.Username = "";
            $login.Password = "";
        }

        Log 6 "Saving Config files at $config_path";
        $config | ConvertTo-Json -Depth 2 | Out-File -FilePath $config_path;
        $login | ConvertTo-Json -Depth 2 | Out-File -FilePath ($Path + "\login.json");
        Set-ConfigPath -Path $config_path;
        Log 5 "Finished Generating Configuration-File"
    }
    catch {
        Log 1 $_;
    }
}

Function New-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )
    try {
        Log 5 "Create new File at $Path";
        if ((Test-Path -Path $Path) -eq $false) {
            New-Item -ItemType File -Path $Path -Force -ErrorAction Stop;
        }
    }
    catch [System.IO.DirectoryNotFoundException] {
        Log 1 $_ 
        $splitPath = Split-Path($Path);
        New-Item -ItemType Directory -Path $splitPath -Force;
        New-Item -ItemType File -Path $Path -Force;
        Log 1 "$_ has been caught and the appropriate directory has been generated."
    }
    return $Path;
}

Function Update-Config {
    <#
    .SYNOPSIS
    Updates the current config with the parameters passed along
    .DESCRIPTION
    Gets current Config path, and saves the configuration with the parameters that were passed along for future runs. 
    .EXAMPLE
    PS> Update-Config -LogLevel 0 -ReportPath "C:\examplePath\out"

    Sets LogLevel to zero and ReportPath to "C:\examplePath\out" and saves it into the configuration.
    .Example
    PS> Update-Config -configPath "C:\pathToSomeWhere"

    This will update the config path and set the paths and variables so that the a new config will be placed there and the script works now from there.
    #>

    
    [CmdletBinding(PositionalBinding = $false)]
    param (
        # Help Handling
        [Parameter(Position = 0)][string]$help,
        [Parameter()][switch]$h,

        [Parameter()]
        [string]
        $configPath,

        [Parameter()]
        [string]
        $LoginConfigPath,

        [Parameter()]
        [string]
        $ReportPath,

        [Parameter()]
        [string]
        $LogPath,

        [Parameter()]
        [string]
        $ServerPath,

        [Parameter()]
        [array]
        $server,

        [Parameter()]
        [int]
        $LogLevel = -1,

        [Parameter()]
        [bool]
        $LoggingActivated,

        [Parameter()]
        [bool]
        $LogToConsole,

        [Parameter()]
        [string]
        $SearchStringInventory,

        [Parameter()]
        [bool]
        $DoNotSearchInventory,

        [Parameter()]
        [bool]
        $IgnoreMACAddress,

        [Parameter()]
        [bool]
        $IgnoreSerialNumbers,

        [Parameter()]
        [string]
        $RemoteMgmntField,

        [Parameter()]
        [bool]
        $DeactivateCertificateValidationILO,

        [Parameter()]
        [string]
        $Username,

        [Parameter()]
        [String]
        $Password
    )
    try {
        ## Check if Help must be displayed
        if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
            Get-Help Update-Config -Full;    
        }


        Log 5 "Start Updating Configuraton File"
        $pathToConfig = Get-ConfigPath;
        if (Test-Path -Path $pathToConfig) {
            $config = Get-Config;

            if ($LoginConfigPath.Length -gt 0) { $config.loginConfigPath = $LoginConfigPath; }
            if ($ReportPath.Length -gt 0) { $config.reportPath = $ReportPath; }
            if ($LogPath.Length -gt 0) { $config.logPath = $LogPath; }
            if ($ServerPath.Length -gt 0) { $config.serverPath = $ServerPath; }
            if ($LogLevel -ne -1) { $config.logLevel = $LogLevel; }
            if ($SearchStringInventory.Length -gt 0) { $config.searchStringInventory = $SearchStringInventory; }
            if ($RemoteMgmntField.Length -gt 0) { $config.remoteMgmntField = $RemoteMgmntField; }

            # Set Switch-Value
            if ($null -ne $LoggingActivated) { $config.loggingActived = $LoggingActivated; }
            if ($null -ne $DoNotSearchInventory) { $config.doNotSearchInventory = $DoNotSearchInventory; }
            if ($null -ne $DeactivateCertificateValidationILO) { $config.deactivateCertificateValidation = $DeactivateCertificateValidationILO; }
            if ( $null -ne $LogToConsole) { $config.logToConsole = $LogToConsole; }
            if ($null -ne $IgnoreMACAddress) { $config.ignoreMACAddress = $IgnoreMACAddress; }
            if ($null -ne $IgnoreSerialNumbers) { $config.ignoreSerialNumbers = $IgnoreSerialNumbers; }
            
            # Set ServerArray
            if ($server.Length -gt 0) { 
                Log 6 "Updating Server Configuration."
                if ((Test-Path -Path $config.serverPath) -eq $false) {
                    $serverPath = New-File ($defaultPath + "\server.json"); 
                    $config.serverPath = $serverPath;

                }
                Set-Content -Path ($config.serverPath) -Value ($server | ConvertTo-Json -Depth 2);
            }
        
            # Set Credentials
            if (Test-Path -Path ($config.loginConfigPath)) {
                Log 6 "Updating Credentials."
                $login = Get-Content -Path ($config.loginConfigPath) | ConvertFrom-Json -Depth 3;
                if ($Username.Length -gt 0) { $login.Username = $Username; }
                if ($Password.Length -gt 0) { $login.Password = $Password }
                
                Set-Content -Path ($config.loginConfigPath) -Value ($login | ConvertTo-Json -Depth 3);
            }
            Log 5 ("Saving updated Configuration at " + $config.configPath)

            if ($configPath.Length -gt 0) {
                $config.configPath = $configPath; 
                Copy-Item -Path $pathToConfig -Destination $configPath; 
                Set-ConfigPath -Path $config.configPath; 
                Write-Warning ("Config has been updated to " + (Get-ConfigPath))
            }
            Set-Content -Path (Get-ConfigPath) -Value ($config | ConvertTo-Json -Depth 3);
            
        }
        else {
            throw [System.IO.FileNotFoundException] "No updatable config could be found at $pathToConfig";
        }
    }
    catch {
        # Log 1 
        Write-Host $_
        Write-Host $_.ScriptStackTrace
    }
}

Function Get-Config {
    <#
    .SYNOPSIS
    Returns the current Config
    .DESCRIPTION
    If called, it will read the current config-path and convert it from JSON back to a PS-Object. 
    .EXAMPLE
    PS> Get-Config
    searchForFilesAt                : C:\Users\wernle_y\AppData\Roaming\hpeilo
    configPath                      : C:\Users\wernle_y\AppData\Roaming\hpeilo\config.json
    loginConfigPath                 : C:\Users\wernle_y\AppData\Roaming\hpeilo\login.json
    reportPath                      : C:\Users\wernle_y\AppData\Roaming\hpeilo\out
    serverPath                      : C:\Users\wernle_y\AppData\Roaming\hpeilo\server.json
    logPath                         : C:\Users\wernle_y\AppData\Roaming\hpeilo\logs
    logLevel                        : 0
    loggingActived                  : True
    searchStringInventory           : gfa-sioc-cs-de
    doNotSearchInventory            : False
    remoteMgmntField                : Hostname Mgnt
    deactivateCertificateValidation : True
    logToConsole                    : False
    ignoreMACAddress                : False
    ignoreSerialNumbers             : False
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param (
        # Help Handling
        [Parameter(Position = 0)][string]$help,
        [Parameter()][switch]$h
    )

    if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
        Get-Help Get-Config -Full;    
    }
    else {   
        if ((Test-Path -Path $ENV:HPEILOCONFIG)) {
            return (Get-Content $ENV:HPEILOCONFIG | ConvertFrom-Json -Depth 3);
        }
    }
}

Function Log {
    param(
        [Parameter(Mandatory = $true)]
        [int]
        $Level,

        [Parameter(Mandatory = $true)]
        [string]
        $Message,
        
        [Parameter()]
        [switch]
        $IgnoreLogActive
    )
    try {
        $currentDateTime = Get-Date -Format "yyyy/MM/dd HH:mm:ss`t";
        $saveString = $currentDateTime + $Message;
            
        if (Test-Path -Path $ENV:HPEILOCONFIG) {
            $config = (Get-Content $ENV:HPEILOCONFIG | ConvertFrom-JSON -Depth 3);

            $logPath = $config.logPath;
            $logLevel = $config.logLevel;
            $logActive = $config.loggingActived;
            $logToConsoleActive = $config.logToConsole;

            if ($logPath.Length -gt 0) {
                # Path set but not existing
                if (-not (Test-Path -Path $logPath)) {
                    $logPath = (Register-Directory $logPath).ToString();
                }
            }            
            
            # Log only if activated
            if ($logActive -or $IgnoreLogActive) {
                if ($Level -le $logLevel -or $IgnoreLogActive) {
                    if ((Test-Path -Path $logPath) -eq $false) {
                        # Directory does not exist$
                        Write-Warning ("No Path for logging exists. Logs will be stored at '" + $ENV:HPEILOCONFIG + "\logs'.")
                        $defaultLogPath = ($defaultPath + "\logs");
                        New-Item -ItemType Directory $defaultLogPath -Force;
                        Update-Config -LogPath $defaultLogPath;
                        $logPath = $defaultLogPath;
                    }
                    $logFilePath = "$logPath\" + (Get-Date -Format "yyyy_MM_dd") + ".txt";


                    # If LogActive is ignored, log only to console.
                    if (-not $IgnoreLogActive) {
                        # File already exists
                        if (Test-Path -Path $logFilePath) {
                            Add-Content -Path $logFilePath -Value $saveString;
                        }
                        else {
                            # File does not exist
                            Set-Content -Path $logFilePath -Value $saveString -Force;
                        }
                    }
                    
                    if ($logToConsoleActive -or $IgnoreLogActive) {
                        Write-Host ($saveString);
                    }
                }
            }
        }
    }
    catch {
        Write-Error $_;
    }
}

Function Invoke-PingTest {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Hostname
    )
    try {
        $nsl = nslookup.exe $Hostname;
        if ($nsl.Length -gt 3) {
            $dnsname = ($nsl | Select-String -Pattern "Name:").Line.Split(":").Trim()[1];   
            # Reachable via NSLookup, but insufficient permissions
            if ((Test-Connection $dnsname -Count 1 -Quiet) -eq $false) {
                Log 2 "$Hostname was found via nslookup but could not be reached. Verify that you have appropriate permissions within your network to access it."
                return $false
            }
            # Reachable
            else { return $true; }
            # Not Reachable via NSlookup
            else {
                Log 2 "$Hostname is not reachable from within this network and could not be found via nslookup."
                return $false
            }
        }
    }
    catch {    
        $_
    }
}