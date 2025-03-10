Remove-Module ILO-Inventorizer;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Get-HWInfoFromILO -serverPath "C:\Users\wernle_y\AppData\Roaming\hpeilo\s\server.json" -Password "test" -Username "Yannik";