Remove-Module ILO-Inventorizer;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
#Get-HWInfoFromILO -LogToConsole

Execute-PingTest "rmgfa-sioc-cs-de"