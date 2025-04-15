Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;


Set-ConfigPath -Reset
Get-ServerByScanner -LogPath "C:\Users\wernle_y\AppData\Roaming\hpeilo\Scanner" -ReportPath "C:\Users\wernle_y\AppData\Roaming\hpeilo\Scanner";