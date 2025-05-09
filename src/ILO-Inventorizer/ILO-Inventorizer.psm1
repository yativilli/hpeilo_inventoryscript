<#
.SYNOPSIS
Scripting-Module to query information from HPE-Servers via ILO
#>

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\General_Functions.ps1
. $PSScriptRoot\QueryInventory.ps1
. $PSScriptRoot\QueryILO.ps1
. $PSScriptRoot\ILO-Inventorizer_Functions.ps1
. $PSScriptRoot\Configuration_Functions.ps1
. $PSScriptRoot\Server_Scanner.ps1

# Main Function
Function Get-HWInfoFromILO {
    <#
    .SYNOPSIS
    Main function used for starting the ILO-query.
    .DESCRIPTION
    This function is the main function for starting the program.
    It will first check for a config file - if none is found, you'll be prompted to either:
    1. Generate an empty one or 
    2. Generate one filled with example data or 
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
        [Parameter(Mandatory = $true, ParameterSetName = "ServerPath")]
        [Parameter()]
        [string]
        $ServerPath,

        # Array that will be used for an ILO-Query instead of Inventory
        [Parameter(Mandatory = $true, ParameterSetName = "ServerArray")]
        [psobject]
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
        [Parameter(ParameterSetName = "ServerPath")]
        [Parameter(ParameterSetName = "ServerArray")]
        [Parameter(ParameterSetName = "Inventory")]
        [Parameter(ParameterSetName = "None")]
        [string]
        $Username,

        # Password for the ILO-Interface
        [Parameter(ParameterSetName = "ServerPath")]
        [Parameter(ParameterSetName = "ServerArray")]
        [Parameter(ParameterSetName = "Inventory")]
        [Parameter(ParameterSetName = "None")]
        [securestring]
        $Password,

        # Keep Temporary Configurations after use
        [Parameter()]
        [switch]
        $KeepTemporaryConfig


    )
    try {
        Log 0 "--------------------------------------`nILO-Inventorizer has been started." -IgnoreLogActive;

        ## Check if Help must be displayed
        if (($h ) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
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
            if ($RECOMMENDED_VERSION -ne ($moduleVersion)) {
                Write-Warning "The installed Module HPEiLOCmdlets doesnt use the recommended Version '$RECOMMENDED_VERSION', but '$moduleVersion' - some features may not work correctly."
            }

            # Check for Parameterset for configuration
            Log 3 "Configure new Configuration"
            Invoke-ParameterSetHandler -ParameterSetName ($PSCmdlet.ParameterSetName) -ConfigPath $ConfigPath -LoginPath $LoginConfigPath;
            Log 3 "Import Configuration"
            # Update Config with any Parameters passed along
            $PSBoundParameters | Optimize-ParameterStartedForUpdate; 
       
            # Check that all Paths needed in the future are set and exist
   
            Convert-PathsToValidated -IgnoreServerPath;
            $config = Get-Config;

            # Query Inventory
            if (-not $config.doNotSearchInventory) {
                Log 3 "Query from Inventory started."
                Get-ServersFromInventory | Out-Null;
            }

            # Verify that the ServerPath also exists
            Convert-PathsToValidated -IgnoreServerPath;
            
            # Execute PingTest
            $reachableServers = Start-PingtestOnServers;
        
            # Query ILO
            $config = Get-Config;
            Log 3 "Query from ILO Started"
            if ($reachableServers.Count -gt 0) {
                $login = Get-Content -Path $config.loginConfigPath | ConvertFrom-Json -Depth 2;

                $report = Get-DataFromILO $reachableServers -Login $login;
                Log 3 ($report | ConvertTo-Json -Depth 10) -IgnoreLogActive;

                # Save Result to JSON and CSV-Files
                Log 3 "Begin Saving result in Files"
                Save-DataInJSON $report;
                Save-DataInCSV $report;
            }
            else {
                throw [System.Data.DataException] "No Servers could be found. Please verify that either your server.json or inventory has at least one Server and is reachable via nslookup and ping. Check also if doNotSearchInventory is set to the appropriate value."
            }
            #>

            Log 2 "ILO-Inventorizer has been executed successfully."
            if ($PSCmdlet.ParameterSetName -ne "None" -and (-not $KeepTemporaryConfig)) {
                Restore-Conditions;
            }
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
        Write-Host $_.ScriptStackTrace
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
                if (($h ) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
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
                if (Test-Path -Path $Path) {
                    $checkForFile = $Path | Split-Path -Extension
                    if ($checkForFile.Length -ne 0) {
                        Log 6 "Config Path already contains file"
                        $ENV:HPEILOCONFIG = $Path;
                    }
                    else {
                        Log 6 "Config Path is a directory, Path does not contain config.json. "
                        $jsonPath = $Path + "\config.json";
                        $tmpPath = $Path + "\config.tmp";
                        if (Test-Path -Path $jsonPath) {
                            Log 6 "Config Path directory contains a config.json"
                            $ENV:HPEILOCONFIG = $jsonPath;
                        }elseif(Test-Path -Path $tmpPath){
                            Log 6 "Config Path directory contains a config.tmp"
                            $ENV:HPEILOCONFIG = $tmpPath;
                        }
                        else {
                            Log 6 "Config Path does not include a config.json in its path or directory."
                            throw [System.IO.FileNotFoundException] "The Path '$Path' must include a 'config.json' or 'config.tmp'."
                        } 
                    }
                }
                else {
                    throw [System.Management.Automation.ItemNotFoundException] "The path '$Path' does not exist.";
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

        if (($h ) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
            Get-Help Get-ConfigPath -Full;    
        }
        else {   
            if ($ENV:HPEILOCONFIG.Length -gt 0) {    
                Log 5 ("Getting config path - " + $ENV:HPEILOCONFIG); 
                return $ENV:HPEILOCONFIG;
            }
            else {
                throw [System.IO.InvalidDataException] "No configuration has been set: Please use 'Set-ConfigPath', 'Get-NewConfig' or 'Get-HWInfoFromILO' to generate a new config";
            }
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
    [2] Generate a config with example data?
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

        if (($h ) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
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
Export-ModuleMember -Function Get-HWInfoFromILO, Set-ConfigPath, Get-ConfigPath, Get-Config, Update-Config, Get-NewConfig, *