. $PSScriptRoot\Constants.ps1

Function Show-Help {
    param(
        [Parameter()]
        [string]
        $helpString
    )
    try {
        if ($helpString.Length -gt 0) {
            switch ($helpstring) {
                { ($_ -eq "/?") -or ($_ -eq "--help") -or ($_ -eq "-h") } {
                    Log 5 "User has requested help -displaying Help-Page" 
                    return $true; 
                    break;
                }
                default {
                    return $false
                    break;
                }
            }
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Convert-PathsToValidated {
    param(
        [Parameter()]
        [switch]
        $IgnoreServerPath
    )

    try {

        $config = Get-Config;
        
        if (-not(Test-Path -Path ($config.searchForFilesAt))) {
            Write-Host $config.searchForFilesAt
            New-Item -ItemType Directory ($config.searchForFilesAt) -Force | Out-Null;
        }

        if ((-not(Test-Path -Path ($config.loginConfigPath)))) {
            New-Item -ItemType Directory ($config.searchForFilesAt) -Force | Out-Null;
            $path = $config.loginConfigPath;
            throw [System.IO.FileNotFoundException] ("Path to '$path' could not be resolved. This path must include some file like 'login.json' and it and the file must exist for the script to work. It also must include a Username and a Password.")
        }

        if ((-not(Test-Path -Path ($config.serverPath))) -and ($IgnoreServerPath -eq $false)) {
            New-Item -ItemType Directory ($config.searchForFilesAt) -Force | Out-Null;
            $path = $config.serverPath;
            throw [System.IO.FileNotFoundException] ("Path to '$path' could not be resolved. This path must include some file like 'server.json' and it and the file must exist for the script to work, with it containing an array of servers.")
        }

        if ((-not(Test-Path -Path ($config.reportPath)))) {
            Write-Host $config.reportPath
            New-Item -ItemType Directory ($config.reportPath) -Force | Out-Null;
        }

        if ((-not(Test-Path -Path ($config.logPath)))) {
            Write-Host $config.logPath
            New-Item -ItemType Directory ($config.logPath) -Force | Out-Null;
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function New-Config {
    param(
        # Path where the config should be stored
        [Parameter(Mandatory = $true)]
        [String]
        $Path,
        
        # Toggle to generate a config with dummydata
        [Parameter()]
        [switch]
        $NotEmpty,
        
        # Toggle to switch off inventory
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
            reportPath                      = $Path
            serverPath                      = ""
            logPath                         = ""
            logLevel                        = ""
            loggingActivated                = $false
            searchStringInventory           = ""
            doNotSearchInventory            = $false
            remoteMgmntField                = ""
            deactivateCertificateValidation = $false
            deactivatePingtest              = $false
            logToConsole                    = $false
            ignoreMACAddress                = $false
            ignoreSerialNumbers             = $false
        };
    
        $login = [ordered]@{
            Username = ""
            Password = ""
        };

        Register-Directory $Path -IgnoreError
        
        ## Generate Dummy (w/o Inventory)
        if ($NotEmpty -and $WithOutInventory) {
            Log 6 "Filling empty config w/o Inventory - generating supplementary 'server.json'"
            $config.reportPath = $Path;
            $config.serverPath = $Path + "\server.json";
            $config.logPath = $Path;
            $config.logLevel = 0;
            $config.loggingActivated = $true;
            $config.logToConsole = $true;
            $config.searchStringInventory = "";
            $config.doNotSearchInventory = $true;
            $config.remoteMgmntField = "";
            $config.deactivatePingtest = $false;
            $config.deactivateCertificateValidation = $true;

            $login.Username = "SomeFancyUsername";
            $login.Password = "SomeFancyPassword";

            $servers = @("rmgfa-sioc-cs-dev", "rmgfa-sioc-cs-de3", "rmgfa-sioc-de4", "rmdl20test");

            $servers | ConvertTo-Json -Depth 2 | Out-File -FilePath ($Path + "\server.json");
        }
        ## Generate Dummy (w/ Inventory)
        elseif ($NotEmpty) {
            Log 6 "Filling empty config w/ Inventory"   
            $config.reportPath = $Path;
            $config.serverPath = "";
            $config.logPath = $Path;
            $config.logLevel = 0;
            $config.logToConsole = $true;
            $config.loggingActivated = $true;
            $config.searchStringInventory = "rmgfa-sioc-cs";
            $config.doNotSearchInventory = $false;
            $config.deactivatePingtest = $false;
            $config.remoteMgmntField = "Hostname Mgnt";
            $config.deactivateCertificateValidation = $true;

            $login.Username = "SomeFancyUsername";
            $login.Password = "SomeFancyPassword";
        }
        ## Generate empty
        else {
            Log 6 "Filling empty config with no contesnts"
            $config.reportPath = "";
            $config.serverPath = "";
            $config.logPath = "";
            $config.logLevel = 0;
            $config.loggingActivated = $null;
            $config.logToConsole = $null;
            $config.searchStringInventory = "";
            $config.doNotSearchInventory = $null;
            $config.remoteMgmntField = "";
            $config.deactivateCertificateValidation = $null;
            $config.deactivatePingtest = $null;
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
        Save-Exception $_ ($_.Exception.Message.ToString());
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
        return $Path;
    }
    catch [System.IO.DirectoryNotFoundException], [System.IO.FileNotFoundException] {
        Save-Exception $_ ("The Path '$Path' could not be found. Please verify that it exists and doesn't point to nowhere.")
    }
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
        # Show Help if Value is /? or --help
        [Parameter(Position = 0)][string]$help,
        # Show Help if Value is true.
        [Parameter()][switch]$h,

        # Path to the Config.json File
        [Parameter()]
        [string]
        $ConfigPath,

        # Path to the Login.json File
        [Parameter()]
        [string]
        $LoginConfigPath,

        # Path to the directory where the reports will be stored
        [Parameter()]
        [string]
        $ReportPath,

        # Path to the directory where the logs will be stored
        [Parameter()]
        [string]
        $LogPath,

        # Path to a server.json to use insted of searching Inventory
        [Parameter()]
        [string]
        $ServerPath,

        # Array of servers to use instead of searching inventory
        [Parameter()]
        [array]
        $Server,

        # Loglevel between 0 and 6 (the higher the more detailled)
        [Parameter()]
        [int]
        $LogLevel = -1,

        # Toggle to Activate Logging
        [Parameter()]
        [switch]
        $LoggingActivated = $null,

        # Toggle to ActivateLogging to Console
        [Parameter()]
        [switch]
        $LogToConsole = $null,

        # String that will be used to search inventory
        [Parameter()]
        [string]
        $SearchStringInventory,

        # Toggle to deactivate searching in Inventory
        [Parameter()]
        [switch]
        $DoNotSearchInventory = $null,

        # Toggle to deactivate generation of MACAddress.csv
        [Parameter()]
        [switch]
        $IgnoreMACAddress = $null,
        
        # Toggle to deactivate generation of SerialNumbers.csv
        [Parameter()]
        [switch]
        $IgnoreSerialNumbers = $null,

        # Toggle Pingtest
        [Parameter()]
        [switch]
        $DeactivatePingtest = $null,

        # Field in Inventory tha'll be used as Hostname for the ILO
        [Parameter()]
        [string]
        $RemoteMgmntField,

        # Toggle Certification process with when connecting with ilo
        [Parameter()]
        [switch]
        $DeactivateCertificateValidationILO = $null,

        # Username for ILO-Interface
        [Parameter()]
        [string]
        $Username,

        # Password for ILO-Interface
        [Parameter()]
        [securestring]
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
            if ($ConfigPath.Length -gt 0) { $config.configPath = $ConfigPath; }
            if ($ReportPath.Length -gt 0) { $config.reportPath = $ReportPath; }
            if ($LogPath.Length -gt 0) { $config.logPath = $LogPath; }
            if ($ServerPath.Length -gt 0) { $config.serverPath = $ServerPath; }
            if ($LogLevel -ne -1) { $config.logLevel = $LogLevel; }
            if ($SearchStringInventory.Length -gt 0) { $config.searchStringInventory = $SearchStringInventory; }
            if ($RemoteMgmntField.Length -gt 0) { $config.remoteMgmntField = $RemoteMgmntField; }

            # Set Switch-Value
            if ($null -ne $LoggingActivated) { $config.loggingActivated = [bool]$LoggingActivated; }
            if ($null -ne $DoNotSearchInventory) { $config.doNotSearchInventory = [bool]$DoNotSearchInventory; }
            if ($null -ne $DeactivateCertificateValidationILO) { $config.deactivateCertificateValidation = [bool]$DeactivateCertificateValidationILO; }
            if ( $null -ne $LogToConsole) { $config.logToConsole = [bool]$LogToConsole; }
            if ($null -ne $IgnoreMACAddress) { $config.ignoreMACAddress = [bool]$IgnoreMACAddress; }
            if ($null -ne $IgnoreSerialNumbers) { $config.ignoreSerialNumbers = [bool]$IgnoreSerialNumbers; }
            if ($null -ne $DeactivatePingtest) { $config.deactivatePingtest = [bool]$DeactivatePingtest; }
            
            # Set ServerArray
            if ($Server.Length -gt 0) { 
                Log 6 "Updating Server Configuration."
                if ((Test-Path -Path $config.serverPath) -eq $false) {
                    $serverPath = New-File ($defaultPath + "\server.json"); 
                    $config.serverPath = $serverPath;

                }
                Set-Content -Path ($config.serverPath) -Value ($Server | ConvertTo-Json -Depth 2);
            }
        
            # Set Credentials
            if (Test-Path -Path ($config.loginConfigPath)) {
                Log 6 "Updating Credentials."
                $login = Get-Content -Path ($config.loginConfigPath) | ConvertFrom-Json -Depth 3;
                if ($Username.Length -gt 0) { $login.Username = $Username; }
                if ($Password.Length -gt 0) { $login.Password = (ConvertFrom-SecureString -SecureString $Password -AsPlainText); }
                
                Set-Content -Path ($config.loginConfigPath) -Value ($login | ConvertTo-Json -Depth 3);
            }
            Log 5 ("Saving updated Configuration at " + $config.configPath)

            Set-Content -Path (Get-ConfigPath) -Value ($config | ConvertTo-Json -Depth 3);
            
        }
        else {
            throw [System.IO.FileNotFoundException] "No updatable config could be found at '$pathToConfig'. Verify that a configuration is set to a config.json that exists and verify that the path exists. `nIf you moved the config file, use Set-ConfigPath -Path 'C:\Somewhere' to change it.";
        }
    }
    catch [System.IO.FileNotFoundException], [System.IO.DirectoryNotFoundException] {
        Save-Exception $_ ($_.Exception.ErrorRecord.ToString() + "Verify that all specified path in config.json and parameters exists and any files pointed to exist");
    }
    catch [System.Management.Automation.SetValueInvocationException] {
        Save-Exception $_ ($_.Exception.ErrorRecord.ToString() + " You are missing the specified Property in your Configuration File. To Fix this Error, verify that you have this value set (even if null or empty) somewhere in your config.json");
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Save-Exception {
    param(
        [Parameter(Mandatory = $true)]
        $_,

        [Parameter(Mandatory = $true)]
        $Message
    )
    Log 1 ("$Message`n" + $_.ScriptStackTrace);
    Write-Error ("$Message");
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
    loggingActivated                  : True
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
        # Show Help if Value is /? or --help
        [Parameter(Position = 0)][string]$help,
        # Show Help if Value is true
        [Parameter()][switch]$h
    )
    try {
        if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
            Get-Help Get-Config -Full;    
        }
        else {   
            if ((Test-Path -Path $ENV:HPEILOCONFIG)) {
                $config = (Get-Content $ENV:HPEILOCONFIG | ConvertFrom-Json -Depth 3);

   
                if (
                        ($config.searchForFilesAt -isnot [string]) -or
                        ($config.configPath -isnot [string]) -or 
                        ($config.loginConfigPath -isnot [string]) -or 
                        ($config.reportPath -isnot [string]) -or 
                        ($config.serverPath -isnot [string] -and ($null -ne $config.serverPath)) -or 
                        ($config.logPath -isnot [string]) -or 
                        ($config.logLevel -isnot [int64]) -or 
                        ($config.searchStringInventory -isnot [string] -and ($null -ne $config.searchStringInventory)) -or 
                        ($config.remoteMgmntField -isnot [string]) -or 

                        ($config.LoggingActivated -isnot [bool]) -or 
                        ($config.doNotSearchInventory -isnot [bool]) -or 
                        ($config.deactivateCertificateValidation -isnot [bool]) -or 
                        ($config.logToConsole -isnot [bool]) -or 
                        ($config.ignoreMACAddress -isnot [bool]) -or 
                        ($config.ignoreSerialNumbers -isnot [bool]) -or 
                        ($config.deactivatePingtest -isnot [bool])
                ) {
                    throw [System.IO.InvalidDataException] "Your configuration has wrong types. Please verify that the following types are met:`nlogLevel = int, LoggingActivated = bool, doNotSearchInventory = bool, deactivateCertificateValidation = bool, logToConsole = bool, ignoreMACAddress = bool, ignoreSerialNumbers = bool, deactivatePingtest = bool AND any other fields are of type string."
                }

                
                return $config;
            }
            else {
                throw [System.IO.FileNotFoundException] "No config has been specified. Use either Set-ConfigPath to set Path to an existing one or let one generate by using Get-NewConfig";
            }
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
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
        

        if (($ENV:HPEILOCONFIG.Length -gt 0) -and (Test-Path -Path $ENV:HPEILOCONFIG)) {
            $config = (Get-Content $ENV:HPEILOCONFIG | ConvertFrom-Json -Depth 3);

            $logPath = $config.logPath;
            $logLevel = $config.logLevel;
            if ($logLevel -isnot [int64]) { throw [System.IO.InvalidDataException] "The Loglevel is not of type int. Check if you have passed anything other than a string to it." }
            $logActive = $config.loggingActivated;
            $logToConsoleActive = $config.logToConsole;

            if ($logPath.Length -gt 0) {
                # Path set but not existing
                if (-not (Test-Path -Path $logPath)) { throw [System.IO.DirectoryNotFoundException] "Your provided Path $logPath could not be found. Verify it exists" }
            }            
            
            # Log only if activated
            if ($logActive -or $IgnoreLogActive) {
                if ($Level -le $logLevel -or $IgnoreLogActive) {
                    if ((Test-Path -Path $logPath) -eq $false) {
                        throw [System.IO.DirectoryNotFoundException] "Your provided Path $logPath could not be found. Verify it exists"
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
        else {
            Write-Warning "No path to logfiles exist. Please specify one in your config or via parameter as soon as possible.";
        }
    }
    catch {
        Write-Error $_ ($_.Exception.Message.ToString());
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
            else {
                return $true; 
            }
            # Not Reachable via NSlookup
            else {
                Log 2 "$Hostname is not reachable from within this network and could not be found via nslookup."
                return $false
            }
        }
    }
    catch {    
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}