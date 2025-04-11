Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;

Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Set-PSDebug -Trace 0

Set-ConfigPath -Path "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\dump\config.json";
Update-Config -SearchForFilesAt "f" -ConfigPath "c" -LogLevel 100;