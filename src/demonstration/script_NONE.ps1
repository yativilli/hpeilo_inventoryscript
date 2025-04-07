Remove-Item -Path "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\dump\*" -Recurse -Force;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;
Set-ConfigPath -Reset;

Get-HWInfoFromILO;