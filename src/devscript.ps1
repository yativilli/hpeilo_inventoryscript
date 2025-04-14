Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;
try {
    Set-PSDebug -Trace 0
    Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
    Import-Module HPEiLOCmdlets;
}
catch {
    $_
}

Set-PSDebug -Trace 0

Set-ConfigPath -Reset
Get-ServerByScanner;