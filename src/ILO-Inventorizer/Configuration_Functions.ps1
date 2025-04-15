. $PSScriptRoot\Constants.ps1

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

        # Path to where some output files will be located
        [Parameter()]
        [string]
        $SearchForFilesAt,

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
        $LoggingActivated,

        # Toggle to ActivateLogging to Console
        [Parameter()]
        [switch]
        $LogToConsole,

        # String that will be used to search inventory
        [Parameter()]
        [string]
        $SearchStringInventory,

        # Toggle to deactivate searching in Inventory
        [Parameter()]
        [switch]
        $DoNotSearchInventory,

        # Toggle to deactivate generation of MACAddress.csv
        [Parameter()]
        [switch]
        $IgnoreMACAddress,
        
        # Toggle to deactivate generation of SerialNumbers.csv
        [Parameter()]
        [switch]
        $IgnoreSerialNumbers,

        # Toggle Pingtest
        [Parameter()]
        [switch]
        $DeactivatePingtest,

        # Field in Inventory tha'll be used as Hostname for the ILO
        [Parameter()]
        [string]
        $RemoteMgmntField,

        # Toggle Certification process with when connecting with ilo
        [Parameter()]
        [switch]
        $DeactivateCertificateValidationILO,

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
        Log 5 "Start Updating Configuraton File"

        ## Check if Help must be displayed
        if (($h ) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
            Get-Help Update-Config -Full;    
        }
        else {     
            $pathToConfig = Get-ConfigPath;
            if (Test-Path -Path $pathToConfig) {
                # Verify if any String or Int-Values are updated and do so accordingly
                Log 6 "`tCheck if any values need to be updated in the configuration"
                $config = $PSBoundParameters | Test-ForChangesToUpdate;

                # Check if ServerArray is set and generate a new file containing them
                if ($Server.Length -gt 0) { 
                    if ((Test-Path -Path $config.serverPath) -eq $false) {
                        Log 6 "`tUpdating Server Configuration."
                        $serverPath = New-File ($DEFAULT_PATH + "\server.json"); 
                        $config.serverPath = $serverPath;

                    }
                    Set-Content -Path ($config.serverPath) -Value ($Server | ConvertTo-Json -Depth 2);
                }
        
                # Set Credentials
                if (Test-Path -Path ($config.loginConfigPath)) {
                    Log 6 "`tUpdating Credentials."
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

Function Test-ForChangesToUpdate {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $BoundParameter
    )
    $config = Get-Config;

    $config.loginConfigPath = ($BoundParameter["LoginConfigPath"] | Resolve-NullValues -ValueOnNull $config.loginConfigPath);
    $config.configPath = ($BoundParameter["ConfigPath"] | Resolve-NullValues -ValueOnNull $config.configPath);
    $config.reportPath = ($BoundParameter["ReportPath"] | Resolve-NullValues -ValueOnNull $config.reportPath);
    $config.logPath = ($BoundParameter["LogPath"] | Resolve-NullValues -ValueOnNull $config.logPath);
    $config.serverPath = ($BoundParameter["ServerPath"] | Resolve-NullValues -ValueOnNull $config.serverPath);
    $config.logLevel = ($BoundParameter["LogLevel"] | Resolve-NullValues -ValueOnNull $config.logLevel);
    $config.searchStringInventory = ($BoundParameter["SearchStringInventory"] | Resolve-NullValues -ValueOnNull $config.searchStringInventory);
    $config.remoteMgmntField = ($BoundParameter["RemoteMgmntField"] | Resolve-NullValues -ValueOnNull $config.remoteMgmntField);
    $config.searchForFilesAt = ($BoundParameter["SearchForFilesAt"] | Resolve-NullValues -ValueOnNull $config.searchForFilesAt);
    
    # Verify if any bool/switch Values are updated and do so accordingly
    if ($LoggingActivated.IsPresent -or $BoundParameter.ContainsKey("LoggingActivated")) { $config.loggingActivated = [bool]$BoundParameter["LoggingActivated"]; }
    if ($DoNotSearchInventory.IsPresent -or $BoundParameter.ContainsKey("DoNotSearchInventory")) { $config.doNotSearchInventory = [bool]$BoundParameter["DoNotSearchInventory"]; }
    if ($LogToConsole.IsPresent -or $BoundParameter.ContainsKey("LogToConsole")) { $config.logToConsole = [bool]$BoundParameter["LogToConsole"]; }
    if ($IgnoreMACAddress.IsPresent -or $BoundParameter.ContainsKey("IgnoreMACAddress")) { $config.ignoreMACAddress = [bool]$BoundParameter["IgnoreMACAddress"]; }
    if ($IgnoreSerialNumbers.IsPresent -or $BoundParameter.ContainsKey("IgnoreSerialNumbers")) { $config.ignoreSerialNumbers = [bool]$BoundParameter["IgnoreSerialNumbers"]; }
    if ($DeactivatePingtest.IsPresent -or $BoundParameter.ContainsKey("DeactivatePingtest")) { $config.deactivatePingtest = [bool]$BoundParameter["DeactivatePingtest"]; }

    return $config; 
}

Function New-Config {
    param(
        # Path where the config should be stored
        [Parameter(Mandatory = $true)]
        [String]
        $Path,
        
        # Toggle to generate a config with exampledata
        [Parameter()]
        [switch]
        $NotEmpty,
        
        # Toggle to switch off inventory
        [Parameter()]
        [switch]
        $WithOutInventory,

        # Toggle to generate Configuration for scanner
        [Parameter()]
        [switch]
        $ForScanner,

        # As Temporary
        [Parameter()]
        [switch]   
        $StoreAsTemporary
    )
    try {
        Log 5 "Started generating new Configuration - intitalising empty object."
        if ($StoreAsTemporary) {
            $config_path = $Path + "hpeilo_config.tmp";
            $login_config_path = $Path + "hpeilo_login.tmp";
        }
        else {
            $config_path = ($Path + "\config.json");
            $login_config_path = ($Path + "\login.json");
        }
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
        
        ## Generate Example (w/o Inventory)
        if ($NotEmpty -and $WithOutInventory) {
            $config | Add-ExampleConfigWithoutInventory -Login $login -Path $Path;
        }
        ## Generate example (w/ Inventory)
        elseif ($NotEmpty) {
            $config | Add-ExampleConfigWithInventory -Login $login -Path $Path;
        }
        # Generate for Scanner
        elseif ($ForScanner) {
            $config | Add-ScannerConfiguration -Path $Path;
        }
        ## Generate empty
        else {
            $config | Add-EmptyConfig -Login $login -Path $Path;
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Add-ExampleConfigWithoutInventory {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $Config,
        
        [Parameter(Mandatory = $true)]
        [psobject]
        $Login,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $StoreAsTemporary
    )
    Log 6 "`tFilling empty config w/o Inventory - generating supplementary 'server.json'"
    if ($StoreAsTemporary) {
        $serverPath = $DEFAULT_PATH_TEMPORARY + "hpeilo_server.tmp";
        $Path = $ENV:TEMP;
    }
    else {
        $serverPath = $Path + "\server.json";
    }
    $Config.reportPath = $Path;
    $Config.serverPath = $serverPath;
    $Config.logPath = $Path;
    $Config.logLevel = 0;
    $Config.loggingActivated = $true;
    $Config.logToConsole = $true;
    $Config.searchStringInventory = "";
    $Config.doNotSearchInventory = $true;
    $Config.remoteMgmntField = "";
    $Config.deactivatePingtest = $false;
    $Config.deactivateCertificateValidation = $true;

    $Login.Username = "SomeFancyUsername";
    $Login.Password = "SomeFancyPassword";

    $servers = @("rmgfa-sioc-cs-dev", "rmgfa-sioc-cs-de3", "rmgfa-sioc-de4", "rmdl20test");
    # Generate example server.json - File
    $servers | ConvertTo-Json -Depth 2 | Out-File -FilePath ($serverPath);

    $Config | Save-Config -Login $Login -Path $Path;
}

Function Add-ExampleConfigWithInventory {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $Config,
        
        [Parameter(Mandatory = $true)]
        [psobject]
        $Login,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $StoreAsTemporary
    )
    if ($StoreAsTemporary) {
        $Path = $ENV:TEMP;
    }
    
    Log 6 "`tFilling empty config w/ Inventory"   
    $Config.reportPath = $Path;
    $Config.serverPath = "";
    $Config.logPath = $Path;
    $Config.logLevel = 0;
    $Config.logToConsole = $true;
    $Config.loggingActivated = $true;
    $Config.searchStringInventory = "rmgfa-sioc-cs";
    $Config.doNotSearchInventory = $false;
    $Config.deactivatePingtest = $false;
    $Config.remoteMgmntField = "Hostname Mgnt";
    $Config.deactivateCertificateValidation = $true;

    $login.Username = "SomeFancyUsername";
    $login.Password = "SomeFancyPassword";

    $Config | Save-Config -Login $Login -Path $Path;
}

Function Add-ScannerConfiguration {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $Config,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $StoreAsTemporary
    )
    if ($StoreAsTemporary) {
        $Path = $ENV:TEMP;
    }
    
    Log 6 "`tFilling empty config for Scanner"   
    $Config.reportPath = $Path;
    $Config.serverPath = "";
    $Config.logPath = ($Config.searchForFilesAt);
    $Config.logLevel = 1;
    $Config.logToConsole = $true;
    $Config.loggingActivated = $true;
    $Config.searchStringInventory = "NONE - Scanner";
    $Config.doNotSearchInventory = $true;
    $Config.deactivatePingtest = $false;
    $Config.remoteMgmntField = "";
    $Config.deactivateCertificateValidation = $true;
    
    $Config | Save-Config -Path $Path;
}

Function Add-EmptyConfig {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $Config,
        
        [Parameter(Mandatory = $true)]
        [psobject]
        $Login,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $StoreAsTemporary
    )
    if ($StoreAsTemporary) {
        $Path = $ENV:TEMP;
    }
    
    Log 6 "`tFilling empty config with no contesnts"
    $Config.reportPath = "";
    $Config.serverPath = "";
    $Config.logPath = "";
    $Config.logLevel = 0;
    $Config.loggingActivated = $null;
    $Config.logToConsole = $null;
    $Config.searchStringInventory = "";
    $Config.doNotSearchInventory = $null;
    $Config.remoteMgmntField = "";
    $Config.deactivateCertificateValidation = $null;
    $Config.deactivatePingtest = $null;
    $Config.ignoreMACAddress = $null;
    $Config.ignoreSerialNumbers = $null;

    $login.Username = "";
    $login.Password = "";

    $Config | Save-Config -Login $Login -Path $Path; 
}

Function Save-Config {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $Config,
        
        [Parameter()]
        [psobject]
        $Login,

        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    Log 6 "`tSaving Config files at $($Config.configPath)";
    $Config | ConvertTo-Json -Depth 2 | Out-File -FilePath ($Config.configPath) -Force;
    if ($null -ne $Login) {
        $Login | ConvertTo-Json -Depth 2 | Out-File -FilePath ($Config.loginConfigPath) -Force;
    }
    Set-ConfigPath -Path $Config.configPath;
    Log 5 "Finished Generating Configuration-File";
}