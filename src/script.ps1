Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;

Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Set-PSDebug -Trace 0

# TF-01
## Get-HWInfoFromILO /?


# TF-02
## Get-HWInfoFromILO -configPath 0
# TF-03
 #Set-ConfigPath -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\config.json"
# Set-ConfigPath -Reset;
# Get-HWInfoFromILO
Get-HWInfoFromILO;
#Get-Config;
<#
# TF-04, TF-05, TF-06, TF-07
Get-NewConfig
# TF-08
Set-ConfigPath -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\Testing\TF08\config.json"
Get-HWInfoFromILO;
# TF-09
Set-ConfigPath -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\Testing\TF08\config.json"
Get-HWInfoFromILO;
# TF-10
Set-ConfigPath -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\Testing\TF10\config.json"
Get-HWInfoFromILO;
# TF-11
Get-HWInfoFromILO -servers @("rmgfa-sioc-cs-dev", "rmgfa-sioc-cs-de4");
# TF-12
Get-HWInfoFromILO -configPath "C:\Users\wernle_y\AppData\Roaming\hpeilo\config.json"
# TF-13
Get-HWInfoFromILO -serverPath "C:\Users\wernle_y\AppData\Roaming\hpeilo\Testing\TF-13\server.json"
# TF-14
Get-HWInfoFromILO -SearchStringInventory "gfa-sioc-cs-de"
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