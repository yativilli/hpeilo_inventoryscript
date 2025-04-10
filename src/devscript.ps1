Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;

Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Set-PSDebug -Trace 0

# Set-ConfigPath -Path "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\prereq\config.json";
$d = Get-Content -Path "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\dump\ilo_report_2025_04_10.json" | ConvertFrom-Json -Depth 10;
$d | Save-MACInformationToCSV;