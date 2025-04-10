Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;

Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Set-PSDebug -Trace 0

# Set-ConfigPath -Path "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\prereq\config.json";
$conn = Connect-HPEILO -Address rmgfa-sioc-cs-dev -Username "Yannik" -Password "test!1234" -DisableCertificateAuthentication;
$conn | Get-PowerSupplyData