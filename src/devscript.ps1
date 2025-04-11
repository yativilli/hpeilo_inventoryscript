Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;

Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Set-PSDebug -Trace 0

Set-ConfigPath -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\Scanner\config.json";
Update-Config -LogToConsole:$false