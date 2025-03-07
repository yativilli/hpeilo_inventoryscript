#Requires -Modules @{ ModuleName="HPEiLOCmdlets"; ModuleVersion="4.4.0.0" }

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Functions.ps1

Function GetHWInfoFromILO{
    Write-Host "Test";
}

Export-ModuleMember -Function GetHWInfoFromILO