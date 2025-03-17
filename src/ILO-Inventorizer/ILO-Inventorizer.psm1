<#
.SYNOPSIS
Scripting-Module to query information from HPE-Servers via ILO
#>

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Functions.ps1
. $PSScriptRoot\QueryInventory.ps1
. $PSScriptRoot\QueryILO.ps1

# Main Function
Function Get-HWInfoFromILO {
    <#
    .SYNOPSIS
    Main function used for starting the ILO-query.
    .DESCRIPTION
    This function is the main function for starting the program.
    It will first check for a config file - if none is found, you'll be prompted to either:
    1. Generate an empty one or 
    2. Generate one filled with dummy data or 
    3. Add the path to an already existing config file.

    After correctly configuring the config, restart this function and depending on your choices,
    1. Inventory.psi.ch will be querried for Hostnames or
    2. An List of Servers you provided will be used as Hostnames.

    After that, it'll execute a pingtest to check if the Servers are reachable.
    If that is the case, it'll beginn querying the ILO-Servers, display the report in the terminal as well as
    1. Saving it as a JSON-File and if not configured otherwise,
    2. Save the most important parts of the report into CSV-Files (MACs, SerialNumbers).

    .EXAMPLE
    PS> Get-HWInfoFromILO¨

    Started with no parameters, will check for config and prompt you to generate or connect one if none exists or,
        will directly execute the pingtest and querries if configured to do so.

    .EXAMPLE
    PS> Get-HWInfoFromILO -configPath "C:\examplePath\config.json"
    
    Will set the config in the background to the specified path and commence from there.

    .EXAMPLE
    PS> Get-HWInfoFromILO -ServerPath "C:\examplePath\server.json"
    
    Will use this path to read Hostnames for the querries from instead of connecting to Inventory

    .EXAMPLE
    PS> Get-HWInfoFromILO -server @("rmgfa-sioc-cs-de", "rmgfa-sioc-cs-dev") 
    
    Will use the specified array to read Hostnames for the querries instead of connecting to Inventory

    .EXAMPLE
    PS> Get-HWInfoFromILO -SearchStringInventory "sf-sioc-cs"
    
    Will check if the search string matches the naming convention and then use it to get the Hostnames from Inventory.psi.ch that match it.
    It'll use those as Hostname for querying ILO.

    .NOTES
    Starting the script with ``Get-HWInfofromILO`` uses different ParameterSets. This assures that one cannot simultaneosly say it should search inventory with a string, but at the same time use an Array instead of Inventory. 
    There are many other parameters that, if set, will edit the in the background to match its value and this saves it for any new runs.
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param (
        # Help Handling
        [Parameter(Position = 0)][string]$help,
        [Parameter()][switch]$h,

        # Config Handling
        [Parameter(
            ParameterSetName = "Config",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = "None")]
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

        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerPath")]
        [Parameter(
            ParameterSetName = "None")]
        [Parameter()]
        [string]
        $ServerPath,

        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerArray")]
        [array]
        $server,

        [Parameter()]
        [int]
        $LogLevel = -1,

        [Parameter()]
        [switch]
        $LoggingActivated,

        [Parameter()]
        [switch]
        $IgnoreMACAddress,

        [Parameter()]
        [switch]
        $IgnoreSerialNumbers,

        [Parameter()]
        [switch]
        $LogToConsole = $null,        

        [Parameter(Mandatory = $true,
            ParameterSetName = "Inventory")]
        [Parameter()]
        [string]
        $SearchStringInventory,

        [Parameter()]
        [switch]
        $DoNotSearchInventory,        

        [Parameter()]
        [string]
        $RemoteMgmntField = "Hostname Mgnt",

        [Parameter()]
        [switch]
        $DeactivateCertificateValidationILO,        

        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerPath")]
        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerArray")]
        [Parameter(Mandatory = $true,
            ParameterSetName = "Inventory")]
        [Parameter(
            ParameterSetName = "Config")]
        [Parameter(
            ParameterSetName = "None")]
        [string]
        $Username,

        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerPath")]
        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerArray")]
        [Parameter(Mandatory = $true,
            ParameterSetName = "Inventory")]
        [Parameter(
            ParameterSetName = "Config")]
        [Parameter(
            ParameterSetName = "None")]
        [String]
        $Password


    )
    try {
        $ErrorActionPreference = 'Stop';
        Log 2 "--------------------------------------`nILO-Inventorizer has been started.";

        ## Check if Help must be displayed
        if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
            Get-Help Get-HWInfoFromILO -Full;    
        }
        else {

            
            Import-Module HPEiLOCmdlets;
            ## Check for recommended ModuleVersion
            $moduleVersion = (Get-Module -Name HPEiLOCmdlets).Version.ToString()
            if ($recommendedVersion -ne ($moduleVersion)) {
                Write-Warning "The installed Module HPEiLOCmdlets doesnt use the recommended Version '$recommendedVersion', but '$moduleVersion' - some features may not work correctly."
            }

            ## Check for Config
            # Check for Parameterset for configuration
            Log 3 "Configure new Configuration"
            $parameterSetName = $PSCmdlet.ParameterSetName;
            switch ($parameterSetName) {
                "Config" { 
                    Log 6 "Started with 'Config' ParameterSet."
                    Set-ConfigPath -Path $configPath;
                    break;
                }
                "ServerPath" {
                    Log 6 "Started with 'ServerPath' ParameterSet."
                    $path = New-File -Path ($defaultPath);
                    New-Config -Path $path;
                    $DoNotSearchInventory = $true;
                    break;
                }
                "ServerArray" {
                    Log 6 "Started with 'ServerArray' ParameterSet."
                    $path = New-File -Path ($defaultPath);
                    New-Config -Path $path;
                    $DoNotSearchInventory = $true;
                    break;
                }
                "Inventory" {
                    Log 6 "Started with 'Inventory' ParameterSet."
                    $path = New-File -Path ($defaultPath);
                    New-Config -Path $path;
                    break;
                }
                default {
                    if ($ENV:HPEILOCONFIG.Length -eq 0) {
                        Log 6 "Started without specific Parameterset - displaying configuration prompt."
                        Write-Host "No Configuration has been found. Would you like to:`n[1] Generate an empty config? `n[2] Generate a config with dummy data?`n[3] Add Path to an Existing config?";
                        [int]$configDecision = Read-Host -Prompt "Enter the corresponding number:";
            
                        switch ($configDecision) {
                            1 {
                                Log 6 "User has selected generating empty config"
                                $pathToSaveAt = Read-Host -Prompt "Where do you want to save the config at?";
                                New-Config -Path $pathToSaveAt;
                                break;
                            }
                            2 {
                                Log 6 "User has selected generating a config with dumydata."
                                $pathToSaveAt = Read-Host -Prompt "Where do you want to save the config at?";
                                $withInventory = Read-Host -Prompt "Do you want to:`nRead From Inventory [y/N]?"
                                switch ($withInventory) {
                                    "y" {
                                        New-Config -Path $pathToSaveAt -NotEmpty;
                                        break;
                                    }
                                    "N" {
                                        New-Config -Path $pathToSaveAt -WithoutInventory -NotEmpty;
                                        break;
                                    }
                                }
                                break;
                            }
                            3 {
                                Log 6 "User has selected adding existing config"
                                $pathToConfig = Read-Host -Prompt "Where dou you have the config stored at?";
                                Set-ConfigPath -Path $pathToConfig;
                                break;
                            }
                        }
                        return;   
                    }
                    else {
                        # Set Standard Values for Updating Configurations
                        $config = Get-Config;
                        $configPath = $config.Length -gt 0 ? $configPath : $config.configPath;
                        $LoginConfigPath = $LoginConfigPath.Length -gt 0 ? $LoginConfigPath : $config.loginConfigPath;
                        $ReportPath = $ReportPath.Length -gt 0 ? $ReportPath : $config.reportPath;
                        $LogPath = $LogPath.Length -gt 0 ? $LogPath : $config.logPath;
                        $ServerPath = $ServerPath.Length -gt 0 ? $ServerPath : $config.serverPath;
                        $LogLevel = $LogLevel -ne -1 ? $LogLevel : $config.logLevel;
                        $LogToConsole = $PSBoundParameters.ContainsKey('LogToConsole') -eq $true ? $LogToConsole : $config.logToConsole ;
                        $LoggingActivated = $PSBoundParameters.ContainsKey('LoggingActivated') -eq $true ? $LoggingActivated : $config.loggingActived;
                        $DoNotSearchInventory = $PSBoundParameters.ContainsKey('LoggingActivated') -eq $true ? $DoNotSearchInventory : $config.doNotSearchInventory ;
                        $DeactivateCertificateValidationILO = $PSBoundParameters.ContainsKey('LoggingActivated') -eq $true ? $DeactivateCertificateValidationILO : $config.deactivateCertificateValidation;
                    
                        $SearchStringInventory = $SearchStringInventory.Length -gt 0 ? $SearchStringInventory : $config.searchStringInventory;
                        $RemoteMgmntField = $RemoteMgmntField.Length -gt 0 ? $RemoteMgmntField : $config.remoteMgmntField;
                    
                        $login = (Get-Content ($LoginConfigPath) | ConvertFrom-Json -Depth 3);
                        $Username = $Username.Length -gt 0 ? $Username : $login.Username;
                        $Password = $Password.Length -gt 0 ? $Password : $login.Password;
                    }
                }
            }
            Log 3 "Import Configuration"
            Update-Config -configPath $configPath -LoginConfigPath $LoginConfigPath -ReportPath $ReportPath -LogPath $LogPath -ServerPath $ServerPath -server $server -LogLevel $LogLevel -IgnoreMACAddress $IgnoreMACAddress -IgnoreSerialNumbers $IgnoreSerialNumbers -LogToConsole $LogToConsole -LoggingActivated $LoggingActivated -SearchStringInventory $SearchStringInventory -DoNotSearchInventory $DoNotSearchInventory -RemoteMgmntField $RemoteMgmntField -DeactivateCertificateValidationILO $DeactivateCertificateValidationILO -Username $Username -Password $Password;
            $config = Get-Config;
        
            if (-not $config.doNotSearchInventory) {
                Log 3 "Query from Inventory started."
                Get-ServersFromInventory;
            }
 
            Log 3 "Start Pingtest"
            $config = Get-Config;
            $serverJSON = Get-Content ($config.serverPath) | ConvertFrom-JSON -Depth 2;
            [Array]$reachable = @();
            foreach ($srv in $serverJSON) {
                if (Invoke-PingTest $srv) {
                    $reachable += $srv;
                }
            }
        
            Log 3 "Query from ILO Started"
            Get-DataFromILO $reachable;

            Log 2 "ILO-Inventorizer has been executed successfully."
        }
    }
    catch {
        Write-Host $_
        Write-Host $_.ScriptStackTrace
        Log 1 ($_.Exception)
        Log 1 ($_.ScriptStackTrace);
    }
}


Function Set-ConfigPath {
    <#
    .SYNOPSIS
    Sets the Config Path for the entire script to a new place
    .DESCRIPTION
    If called, this will override the current path and set it to another config.json-File.
    The entire execution of the script hinges on the config, so make sure it is contains all values needed. Otherwise, it might crash.
    
    Upon Setting a new Path, it will be validated, if it contains any config.json (it MUST)
    .EXAMPLE
    PS> Set-ConfigPath -Path "C:\examplePath\config.json";

    Will change the path to the config to "C:\examplePath\config.json"
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Position = 0, ParameterSetName = "Help")][string]$help,
        [Parameter(ParameterSetName = "Help")][switch]$h,
        
        [Parameter(Mandatory = $true,
            ParameterSetName = "SetPath")]
        [string]
        $Path,

        [Parameter(Mandatory = $true,
            ParameterSetName = "ResetPath")]
        [switch]
        $Reset
    )try {
        ## Check if Help must be displayed
        switch ($PSCmdlet.ParameterSetName) {
            "Help" { 
                if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
                    Get-Help Set-ConfigPath -Full;    
                }
                break;
            }
            "ResetPath" {
                if ($Reset) {
                    $ENV:HPEILOCONFIG = "";
                }
                break;
            }
            Default {

                Log 5 "Set Config Path has been started with 'Path' $Path and reset:$Reset"
                
                if (Test-Path -Path $Path -ErrorAction Stop) {
                    if ($Path.Contains("\config.json")) {
                        Log 6 "Config Path already contains config.json"
                        $ENV:HPEILOCONFIG = $Path;
                    }
                    else {
                        Log 6 "Config Path is a directory, Path does not contain config.json. "
                        $Path = $Path + "\config.json";
                        if (Test-Path -Path $Path) {
                            Log 6 "Config Path directory contains a config.json"
                            $ENV:HPEILOCONFIG = $Path;
                        }
                        else {
                            Log 6 "Config Path does not include a config.json in its path or directory."
                            throw [System.IO.FileNotFoundException] "The Path must include a 'config.json'."
                        } 
                    }
                }
                Log 5 ("Config Path has successfully been set to '" + $ENV:HPEILOCONFIG + "'")
                break;
            }
        }
        
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Log 1 $_
        Write-Error "The Path $Path does not exist. Please verify that it exists."
    }
    catch {
        Log 1 $_
        Write-Error $_;
        Write-Error $_.ScriptStackTrace;
    }
}

Function Get-ConfigPath {
    <#
    .SYNOPSIS
    Returns the current path to the current config.json as a string.
    .DESCRIPTION
    If called, it will return
    .EXAMPLE
    PS> Get-NewConfig
    C:\Users\wernle_y\AppData\Roaming\hpeilo\config.json    

    Will reset the current config and bring up the screen to generate a new one.
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Position = 0, ParameterSetName = "Help")][string]$help,
        [Parameter(ParameterSetName = "Help")][switch]$h
    )
    if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
        Get-Help Get-ConfigPath -Full;    
    }
    else {   
        Log 5 ("Getting config path - " + $ENV:HPEILOCONFIG); 
        return $ENV:HPEILOCONFIG;
    }
}

Function Get-NewConfig {
        <#
    .SYNOPSIS
    Brings up the screen to generate a new Config
    .DESCRIPTION
    If called, it will reset the current configuration path and bring up the screen from Get-HWInfoFrmILO to generate a new one or set the path to an already existing one.
    .EXAMPLE
    PS> Get-NewConfig
    No Configuration has been found. Would you like to:
    [1] Generate an empty config?
    [2] Generate a config with dummy data?
    [3] Add Path to an Existing config?

    Will reset the current config and bring up the screen to generate a new one.
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Position = 0, ParameterSetName = "Help")][string]$help,
        [Parameter(ParameterSetName = "Help")][switch]$h
    )
    if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
        Get-Help Get-ConfigPath -Full;    
    }
    else {   
        Set-ConfigPath -Reset;
        Get-HWInfoFromILO
    }
}
Export-ModuleMember -Function Get-HWInfoFromILO, Set-ConfigPath, Get-ConfigPath, Get-Config, Update-Config, Get-NewConfig
