Remove-Module ILO-Inventorizer;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
# Get-HWInfoFromILO -LogToConsole
#Get-HWInfoFromILO -server @("rmgfa-sioc-cs-dev", "rmgfa-sioc-cs-de4", "rmgfa-sioc-cs-de3", "rmdl20test") -Password "test!1234" -Username "Yannik"
Import-Module HPEiLOCmdlets;
Get-DataFromILO -servers @("rmgfa-sioc-cs-dev", "rmgfa-sioc-cs-de4", "rmgfa-sioc-cs-de3", "rmdl20test");