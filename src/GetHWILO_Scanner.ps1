Remove-Module ILO-Inventorizer;

Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Get-ServerByScanner;