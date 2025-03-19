Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;

Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Set-PSDebug -Trace 0



# TF-14
Get-HWInfoFromILO -SearchStringInventory "gfa-sioc-cs-de" -Password (ConvertTo-SecureString -String "test!1234" -AsPlainText) -Username "Yannik" -DeactivateCertificateValidationILO -IgnoreMACAddress -DeactivatePingtest

<#
# TF-15
Uninstall-Module HPEiLOCmdlets;
Install-Module HPEiLOCmdlets -RequiredVersion 4.0.0.0
Import-Module
Get-HWInfoFromILO -SearchStringInventory "gfa-sioc-cs-de"
# TF-16
Set-ConfigPath -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\config.json"
Get-HWInfoFromILO
# TF-17
Set-ConfigPath -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\Testing\TF17\config.json"
Get-HWInfoFromILO
# TF-18
Set-ConfigPath -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\Testing\TF18\config.json"
Get-HWInfoFromILO
#>