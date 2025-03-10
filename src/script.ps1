Remove-Module ILO-Inventorizer;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Get-HWInfoFromILO -SearchStringInventory "sf-sioc" -LoggingActivated -Password "test" -Username "Yannik";