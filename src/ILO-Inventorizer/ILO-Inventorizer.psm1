<#
.SYNOPSIS
Scripting-Module to query information from HPE-Servers via ILO
#>

#Requires -Modules @{ ModuleName="HPEiLOCmdlets"; ModuleVersion="4.4.0.0" }

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Functions.ps1

# Main Function
Function GetHWInfoFromILO{
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(Position=0)]
        [string]
        $help
    )

    Show-Help $help;

}

Export-ModuleMember -Function GetHWInfoFromILO