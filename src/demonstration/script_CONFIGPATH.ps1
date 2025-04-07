Remove-Item -Path "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\dump\*" -Recurse -Force;
Update-Config -Server "" -LoggingActivated -DeactivateCertificateValidationILO;
Set-ConfigPath -Reset;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Get-HWInfoFromILO -ConfigPath "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\prereq\config.json";