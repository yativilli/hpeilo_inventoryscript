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
        # Show Help if Value either /? or --help
        [Parameter(Position = 0)][string]$help,
        
        # Show Help if Value is true.
        [Parameter()][switch]$h,

        # Path to a config.json-File
        [Parameter(
            ParameterSetName = "Config",
            Mandatory = $true
        )]
        [string]
        $ConfigPath,

        # Path to a login.json file that contains 'Username' and 'Password'
        [Parameter()]
        [string]
        $LoginConfigPath,

        # Path to a folder where the output will be saved to 
        [Parameter()]
        [string]
        $ReportPath,
    
        # Path to a folder where the logfiles will be saved to
        [Parameter()]
        [string]
        $LogPath,

        # Path to a server.json, which will be used for the ILO-Query instead of Inventory (when doNotSearchInventory is activated)
        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerPath")]
        [Parameter()]
        [string]
        $ServerPath,

        # Array that will be used for an ILO-Query instead of Inventory
        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerArray")]
        [array]
        $Server,

        # Level from 0 to 6 that changes the detail of any logs present (0 - None, 6 - Many)
        [Parameter()]
        [int]
        $LogLevel = -1,

        # Activate or Deactivate Logging
        [Parameter()]
        [switch]
        $LoggingActivated,

        # Toggle if the MAC-Address.csv will be generated
        [Parameter()]
        [switch]
        $IgnoreMACAddress,

        # Toggle if the SerialNumbers.csv will be generated
        [Parameter()]
        [switch]
        $IgnoreSerialNumbers,

        # Toggle if the Logs should also be printed into the console
        [Parameter()]
        [switch]
        $LogToConsole,  

        # Toggle if the Pingtest is executed
        [Parameter()]
        [switch]
        $DeactivatePingtest,

        # String that will be used to query Inventory.psi.ch (must be like 'sf-', 'gfa-' or 'sls-)
        [Parameter(Mandatory = $true,
            ParameterSetName = "Inventory")]
        [Parameter()]
        [string]
        $SearchStringInventory,

        # Toggle if Inventory should be queried or not
        [Parameter()]
        [switch]
        $DoNotSearchInventory,        

        # Change Field that is used for the Management Hostname
        [Parameter()]
        [string]
        $RemoteMgmntField = "Hostname Mgnt",

        # Toggle CertificateValidation with the ILO-Server when querrying.
        [Parameter()]
        [switch]
        $DeactivateCertificateValidationILO,        

        # Username for the ILO-Interface
        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerPath")]
        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerArray")]
        [Parameter(Mandatory = $true,
            ParameterSetName = "Inventory")]
        [Parameter(
            ParameterSetName = "None")]
        [string]
        $Username,

        # Password for the ILO-Interface
        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerPath")]
        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerArray")]
        [Parameter(Mandatory = $true,
            ParameterSetName = "Inventory")]
        [Parameter(
            ParameterSetName = "None")]
        [securestring]
        $Password


    )
    try {
        $ErrorActionPreference = 'Stop';
        Log 0 "--------------------------------------`nILO-Inventorizer has been started." -IgnoreLogActive;

        ## Check if Help must be displayed
        if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
            Get-Help Get-HWInfoFromILO -Full;    
        }
        else {

            try {
                Import-Module HPEiLOCmdlets -ErrorAction Stop;
            }
            catch [System.IO.FileNotFoundException] {
                Write-Error ("No HPEiLOCmdlets-Module is installed. Please install it from 'https://www.powershellgallery.com/packages/HPEiLOCmdlets/4.4.0.0'") ;
                return;
            }
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
                    # Started with Path to Config as Parameter
                    Log 6 "Started with 'Config' ParameterSet."
                    Set-ConfigPath -Path $ConfigPath;
                    break;
                }
                "ServerPath" {
                    # Started with Path to Servers as Parameter
                    Log 6 "Started with 'ServerPath' ParameterSet."
                    $path = New-File -Path ($defaultPath);
                    New-Config $path -NotEmpty -WithOutInventory;
                    Update-Config -DoNotSearchInventory $true;
                    break;
                }
                "ServerArray" {
                    # Started with Array of Servers as Parameter
                    Log 6 "Started with 'ServerArray' ParameterSet."
                    $path = New-File -Path ($defaultPath);
                    New-Config -Path $path -NotEmpty -WithOutInventory;
                    Update-Config -DoNotSearchInventory $true;
                    break;
                }
                "Inventory" {
                    # Started with SearchStringInventory as Parameter
                    Log 6 "Started with 'Inventory' ParameterSet."
                    $path = New-File -Path ($defaultPath);
                    New-Config -Path $path -NotEmpty;
                    break;
                }
                default {
                    # Started without any Parameters that would trigger something different than an update to the configuration
            
                    # No Config Found
                    if ($ENV:HPEILOCONFIG.Length -eq 0) {
                        Log 6 "Started without specific Parameterset - displaying configuration prompt."
                        Write-Host "No Configuration has been found. Would you like to:`n[1] Generate an empty config? `n[2] Generate a config with dummy data?`n[3] Add Path to an Existing config?";
                        [int]$configDecision = Read-Host -Prompt "Enter the corresponding number:";
            
                        switch ($configDecision) {
                            1 {
                                # Generate Empty Config
                                Log 6 "User has selected generating empty config"
                                $pathToSaveAt = Read-Host -Prompt "Where do you want to save the config at?";
                                if ((Test-Path $pathToSaveAt) -eq $false) { throw [System.IO.DirectoryNotFoundException] "The path provided ('$pathToSaveAt') does not exist. Verify that it does" }
                                New-Config -Path $pathToSaveAt;
                                break;
                            }
                            2 {
                                # Generate Config with Dummydata
                                Log 6 "User has selected generating a config with dumydata."
                                $pathToSaveAt = Read-Host -Prompt "Where do you want to save the config at?";
                                if ((Test-Path $pathToSaveAt) -eq $false) { throw [System.IO.DirectoryNotFoundException] "The path provided ('$pathToSaveAt') does not exist. Verify that it does" }
                                $withInventory = Read-Host -Prompt "Do you want to:`nRead From Inventory [y/N]?"
                                switch ($withInventory) {
                                    "y" {
                                        # Generate with Inventory-Preset
                                        New-Config -Path $pathToSaveAt -NotEmpty;
                                        break;
                                    }
                                    "N" {
                                        # Generate with ServerPath-Preset
                                        New-Config -Path $pathToSaveAt -WithoutInventory -NotEmpty;
                                        break;
                                    }
                                }
                                break;
                            }
                            3 {
                                # Add Path to Config
                                Log 6 "User has selected adding existing config"
                                $pathToConfig = Read-Host -Prompt "Where dou you have the config stored at?";
                                if (Test-Path $pathToConfig) {
                                    Set-ConfigPath -Path $pathToConfig;
                                }
                                else {
                                    throw [System.IO.FileNotFoundException] "The specified path $pathToConfig could not be found. Verify that it exists and contains a 'config.json'"
                                }
                                break;
                            }
                        }
                        return;   
                    }
                    elseif ($ENV:HPEILOCONFIG -gt 0) {
 
                    }
                    else {
                        return;
                    }
                }
            }
            Log 3 "Import Configuration"
            # Update Config with any Parameters passed along
            $config = Get-Config;
            $ConfigPath = $config.Length -gt 0 ? $ConfigPath : $config.configPath;
            $LoginConfigPath = $LoginConfigPath.Length -gt 0 ? $LoginConfigPath : $config.loginConfigPath;
            $ReportPath = $ReportPath.Length -gt 0 ? $ReportPath : $config.reportPath;
            $LogPath = $LogPath.Length -gt 0 ? $LogPath : $config.logPath;
            $ServerPath = $ServerPath.Length -gt 0 ? $ServerPath : $config.serverPath;
            $LogLevel = $LogLevel -ne -1 ? $LogLevel : $config.logLevel;
            
            $LogToConsole = $PSBoundParameters.ContainsKey('LogToConsole') -eq $true ? $LogToConsole : $config.logToConsole ;
            $LoggingActivated = $PSBoundParameters.ContainsKey('LoggingActivated') -eq $true ? $LoggingActivated : $config.loggingActivated;
            $DoNotSearchInventory = $PSBoundParameters.ContainsKey('DoNotSearchInventory') -eq $true ? $DoNotSearchInventory : $config.doNotSearchInventory ;
            $DeactivateCertificateValidationILO = $PSBoundParameters.ContainsKey('DeactivateCertificateValidationILO') -eq $true ? $DeactivateCertificateValidationILO : $config.deactivateCertificateValidation;
            $DeactivatePingtest = $PSBoundParameters.ContainsKey("DeactivatePingtest") -eq $true ? $DeactivatePingtest : $config.deactivatePingtest;
            $IgnoreMACAddress = $PSBoundParameters.ContainsKey("IgnoreMACAddress") -eq $true ? $IgnoreMACAddress : $config.ignoreMACAddress;
            $IgnoreSerialNumbers = $PSBoundParameters.ContainsKey("IgnoreSerialNumbers") -eq $true ? $IgnoreSerialNumbers : $config.ignoreSerialNumbers;

            $SearchStringInventory = $SearchStringInventory.Length -gt 0 ? $SearchStringInventory : $config.searchStringInventory;
            $RemoteMgmntField = $RemoteMgmntField.Length -gt 0 ? $RemoteMgmntField : $config.remoteMgmntField;
                                   
            $login = (Get-Content ($LoginConfigPath) | ConvertFrom-Json -Depth 3);
            $Username = $Username.Length -gt 0 ? $Username : $login.Username;
                                       
            $Password = $Password.Length -gt 0 ? $Password : $login.Password.Length -ne 0 ? (ConvertTo-SecureString -String ($login.Password) -AsPlainText) : (ConvertTo-SecureString -String ("None") -AsPlainText);
        
            Update-Config -ConfigPath $ConfigPath -LoginConfigPath $LoginConfigPath -ReportPath $ReportPath -LogPath $LogPath -ServerPath $ServerPath -Server $Server -LogLevel $LogLevel -DeactivatePingtest:$DeactivatePingtest -IgnoreMACAddress:$IgnoreMACAddress -IgnoreSerialNumbers:$IgnoreSerialNumbers -LogToConsole:$LogToConsole -LoggingActivated:$LoggingActivated -SearchStringInventory $SearchStringInventory -DoNotSearchInventory:$DoNotSearchInventory -RemoteMgmntField $RemoteMgmntField -DeactivateCertificateValidationILO:$DeactivateCertificateValidationILO -Username $Username -Password $Password;
            $config = Get-Config;

            # Check that all Paths needed in the future are set and exist
            Convert-PathsToValidated -IgnoreServerPath;
            
            # Query Inventory
            if (-not $config.doNotSearchInventory) {
                Log 3 "Query from Inventory started."
                Get-ServersFromInventory | Out-Null;
            }

            # Verify that the ServerPath also exists
            Convert-PathsToValidated -IgnoreServerPath;
            
            # Execute PingTest
            [Array]$reachable = @();
            $config = Get-Config;
            $serverJSON = Get-Content ($config.serverPath) | ConvertFrom-JSON -Depth 2;
            if (-not $config.deactivatePingtest) {
                Log 3 "Start Pingtest"
                foreach ($srv in $serverJSON) {
                    if (Invoke-PingTest $srv) {
                        Log 0 "$srv was successfully reached via Pingtest." -IgnoreLogActive;
                        $reachable += $srv;
                    }
                    else {
                        Log 0 "$srv was not able to be reached via Pingtest." -IgnoreLogActive;
                    }
                }
            }
            else {
                $reachable = $serverJSON;
            }
        
            # Query ILO
            Log 3 "Query from ILO Started"
            if ($reachable.Count -gt 0) {
                Get-DataFromILO $reachable;
            }
            else {
                throw [System.Data.DataException] "No Servers could be found. Please verify that either your server.json or inventory has at least one Server. Check also if doNotSearchInventory is set to the appropriate value."
            }

            Log 2 "ILO-Inventorizer has been executed successfully."
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
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
        # Show Help if Value is either /? or --help
        [Parameter(Position = 0, ParameterSetName = "Help")][string]$help,
        # Show Help if Value is true.
        [Parameter(ParameterSetName = "Help")][switch]$h,
        
        # Path to the new Config you want to set the program to
        [Parameter(Mandatory = $true,
            ParameterSetName = "SetPath")]
        [string]
        $Path,

        # Toggle if the path should be resetted.
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
            "SetPath" {

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
    catch [System.Management.Automation.ItemNotFoundException], [System.IO.FileNotFoundException], [System.IO.DirectoryNotFoundException] {
        Save-Exception $_ ("The Path $Path does not exist. Please verify that it exists and the pact includes a config.json-File");
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
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
        # Show Help if Value is /? or --help 
        [Parameter(Position = 0, ParameterSetName = "Help")][string]$help,
        # Show Help if Value is true.
        [Parameter(ParameterSetName = "Help")][switch]$h
    )
    try {

        if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
            Get-Help Get-ConfigPath -Full;    
        }
        else {   
            Log 5 ("Getting config path - " + $ENV:HPEILOCONFIG); 
            return $ENV:HPEILOCONFIG;
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.ToString());
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
        # Show Help if Value is /? or --help
        [Parameter(Position = 0, ParameterSetName = "Help")][string]$help,
        # Show Help if Value is true.
        [Parameter(ParameterSetName = "Help")][switch]$h
    )
    try {

        if (($h -eq $true) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
            Get-Help Get-ConfigPath -Full;    
        }
        else {   
            Set-ConfigPath -Reset;
            Get-HWInfoFromILO;
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}
Export-ModuleMember -Function Get-HWInfoFromILO, Set-ConfigPath, Get-ConfigPath, Get-Config, Update-Config, Get-NewConfig
