<#
.SYNOPSIS
Scripting-Module to query information from HPE-Servers via ILO
#>

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Functions.ps1

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
        [Parameter()]
        [string]
        $ServerPath,

        [Parameter(Mandatory = $true,
            ParameterSetName = "ServerArray")]
        [Parameter()]
        [array]
        $server,

        [Parameter()]
        [int]
        $LogLevel,

        [Parameter()]
        [switch]
        $LoggingActivated,

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
        $RemoteMgmntField,

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
        [Parameter()]
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
        [Parameter()]
        [String]
        $Password


    )
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
    $parameterSetName = $PSCmdlet.ParameterSetName;
    switch ($parameterSetName) {
        "Config" { 
            Set-ConfigPath -Path $configPath;
            break;
        }
        "ServerPath" {
            $path = New-File -Path ($defaultPath);
            New-Config -Path $path;
            break;
        }
        "ServerArray" {
            $path = New-File -Path ($defaultPath);
            New-Config -Path $path;
            break;
        }
        "Inventory" {
            $path = New-File -Path ($defaultPath);
            New-Config -Path $path;
            break;
        }
        default {
            if ($ENV:HPEILOCONFIG.Length -eq 0) {
                Write-Host "No Configuration has been found. Would you like to:`n[1] Generate an empty config? `n[2] Generate a config with dummy data?`n[3] Add Path to an Existing config?";
                [int]$configDecision = Read-Host -Prompt "Enter the corresponding number:";
            
                switch ($configDecision) {
                    1 {
                        $pathToSaveAt = Read-Host -Prompt "Where do you want to save the config at?";
                        New-Config -Path $pathToSaveAt;
                        break;
                    }
                    2 {
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
                        $pathToConfig = Read-Host -Prompt "Where dou you have the config stored at?";
                        Set-ConfigPath -Path $pathToConfig;
                        break;
                    }
                }
                return;   
            }
        }
    }
    Update-Config -configPath $configPath -LoginConfigPath $LoginConfigPath -ReportPath $ReportPath -LogPath $LogPath -ServerPath $ServerPath -server $server -LogLevel $LogLevel -LoggingActivated $LoggingActivated -SearchStringInventory $SearchStringInventory -DoNotSearchInventory $DoNotSearchInventory -RemoteMgmntField $RemoteMgmntField -DeactivateCertificateValidationILO $DeactivateCertificateValidationILO -Username $Username -Password $Password;
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
        if ($Reset) {
            $ENV:HPEILOCONFIG = "";
        }
        if (Test-Path -Path $Path -ErrorAction Stop) {
            if ($Path.Contains("\config.json")) {
                $ENV:HPEILOCONFIG = $Path;
            }
            else {
                $Path = $Path + "\config.json";
                if (Test-Path -Path $Path) {
                    $ENV:HPEILOCONFIG = $Path;
                }
                else {
                    throw [System.IO.FileNotFoundException] "The Path must include a 'config.json'."
                } 
            }
        }
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error "The Path $Path does not exist. Please verify that it exists."
    }
    catch {
        Write-Error $_;
    }
}

Function Get-ConfigPath {
    return $ENV:HPEILOCONFIG;
}
    
Export-ModuleMember -Function Get-HWInfoFromILO, Set-ConfigPath, Get-ConfigPath, Update-Config, New-File;
