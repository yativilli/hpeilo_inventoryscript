<#
.SYNOPSIS
Scripting-Module to query information from HPE-Servers via ILO
#>

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Functions.ps1
. $PSScriptRoot\QueryInventory.ps1

# Main Function
Function Get-HWInfoFromILO {
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
        [Parameter(
            ParameterSetName = "None")]
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
        $LogToConsole = $null,        

        [Parameter(Mandatory = $true,
            ParameterSetName = "Inventory")]
        [Parameter(
            ParameterSetName = "None")]
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
        Log 2 "--------------------------------------`nILO-Inventorizer has been started.";

        ## Check if Help must be displayed
        if ($h -eq $true) { $help = "-h"; }
        if ($help.Length -gt 0) { Show-Help $help; } 
        
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
                break;
            }
            "ServerArray" {
                Log 6 "Started with 'ServerArray' ParameterSet."
                $path = New-File -Path ($defaultPath);
                New-Config -Path $path;
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
        Update-Config -configPath $configPath -LoginConfigPath $LoginConfigPath -ReportPath $ReportPath -LogPath $LogPath -ServerPath $ServerPath -server $server -LogLevel $LogLevel -LogToConsole $LogToConsole -LoggingActivated $LoggingActivated -SearchStringInventory $SearchStringInventory -DoNotSearchInventory $DoNotSearchInventory -RemoteMgmntField $RemoteMgmntField -DeactivateCertificateValidationILO $DeactivateCertificateValidationILO -Username $Username -Password $Password;
        
        
        Log 3 "Query from Inventory started."
        $wasInventorySuccessfull = Get-ServersFromInventory;
        if (-not $wasInventorySuccessfull) {
            Write-Host "Inventory could not be querried";
        }else{
            Write-Host "Inventory querried";
        }
 
        Log 3 "Start Pingtest"
        $config = Get-Config;
        $serverJSON = Get-Content ($config.serverPath) | ConvertFrom-JSON -Depth 2;
        [Array]$reachable;
        foreach ($srv in $serverJSON) {
            if (Invoke-PingTest $srv) {
                $reachable += $srv;
            }
        }
        
        Log 3 "Query from ILO Started"

        Log 2 "ILO-Inventorizer has been executed successfully."
    }
    catch {
        Log 1 ($_.Exception)
        Log 1 ($_.ScriptStackTrace);
    }
}


Function Set-ConfigPath {
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = "SetPath")]
        [string]
        $Path,

        [Parameter(Mandatory = $true,
            ParameterSetName = "ResetPath")]
        [switch]
        $Reset
    )try {
        Log 5 "Set Config Path has been started with 'Path' $Path and reset:$Reset"
        if ($Reset) {
            $ENV:HPEILOCONFIG = "";
        }
        elseif (Test-Path -Path $Path -ErrorAction Stop) {
            if ($Path.Contains("\config.json")) {
                Log 6 "Config Path already contains config.json"
                $ENV:HPEILOCONFIG = $Path;
            }
            else {
                Log 6 "Config Path is a directory does not contain config.json. "
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
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Log 1 $_
        Write-Error "The Path $Path does not exist. Please verify that it exists."
    }
    catch {
        Log 1 $_
        Write-Error $_;
    }
}

Function Get-ConfigPath {
    Log 5 ("Getting config path - " + $ENV:HPEILOCONFIG); 
    return $ENV:HPEILOCONFIG;
}
    
Export-ModuleMember -Function * -Alias *
#Get-HWInfoFromILO, Set-ConfigPath, Get-ConfigPath, Log;
