<#
.SYNOPSIS
Scripting-Module to query information from HPE-Servers via ILO
#>
#Requires -Modules @{ ModuleName="HPEiLOCmdlets"; ModuleVersion="4.0.0.0"}
    
. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Functions.ps1

# Main Function
Function GetHWInfoFromILO {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        # Help Handling
        [Parameter(Position = 0)][string]$help,
        [Parameter()][switch]$h,

        # Config Handling
        [Parameter(
            ParameterSetName = "Config"
        )]
        [string]
        $configPath,

        # ParameterHandling
        [Parameter(
            ParameterSetName = "Param",
            Mandatory = $true
        )]
        [switch]
        $params
    )
    $Env:hpeiloConfig;

    ## Check if Help must be displayed
    if ($h -eq $true) { $help = "-h"; }
    if ($help.Length -gt 0) { Show-Help $help; } 
        
    ## Check for recommended ModuleVersion
    $moduleVersion = (Get-Module -Name HPEiLOCmdlets).Version.ToString()
    if ($recommendedVersion -ne ($moduleVersion)) {
        Write-Warning "The installed Module HPEiLOCmdlets doesnt use the recommended Version '$recommendedVersion', but '$moduleVersion' - some features may not work correctly."
    }

    ## Check for Config
    if ($param) {
        Write-Host "Param";
    }
    if ($null -eq $Env:hpeiloConfig) {
        Write-Host "No Configuration has been found. Would you like to:`n[1] Generate an empty config? `n[2] Generate a config with dummy data?`n[3] Add Path to an Existing config?";
        [int]$configDecision = Read-Host -Prompt "Enter the corresponding number:";

        switch ($configDecision) {
            1 {
                $pathToSaveAt = Read-Host-Prompt "Where do you want to save the config at?";
                Generate-Config -Path $pathToSaveAt;
                break;
            }
            2 {
                $pathToSaveAt = Read-Host-Prompt "Where do you want to save the config at?";
                $withInventory = Read-Host -Prompt "Do you want to:`n[1] Read from Inventory or From"
                break;
            }
            3 {
                $pathToConfig = Read-Host-Prompt "Where dou you have the config stored at?";
                Set-ConfigPath -Path $pathToConfig;
                break;
            }
        }

            
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
        if ($Reset) {
            $Env:hpeiloConfig = "";
        }
        elseif ((Resolve-Path -Path $Path -ErrorAction Stop).Path -eq $true) {
            $Env:hpeiloConfig = $Path;
        }
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error "The Path $Path does not exist. Please verify that it exists."
    }
}
    
Export-ModuleMember -Function GetHWInfoFromILO, Set-ConfigPath;
