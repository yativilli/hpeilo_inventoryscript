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
        [Parameter(Position = 0)]
        [string]
        $help,

        [Parameter()]
        [switch]
        $h
    )
    ## Check if Help must be displayed
    if($h -eq $true) {$help = "-h";}
    Show-Help $help; 
        
    ## Check for recommended ModuleVersion
    $moduleVersion = (Get-Module -Name HPEiLOCmdlets).Version.ToString()
    if ($recommendedVersion -ne ($moduleVersion)) {
        Write-Warning "The installed Module HPEiLOCmdlets doesnt use the recommended Version '$recommendedVersion', but '$moduleVersion' - some features may not work correctly."
    }
}
    
Export-ModuleMember -Function GetHWInfoFromILO;
