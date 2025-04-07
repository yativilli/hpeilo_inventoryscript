Remove-Item -Path "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\dump\*" -Recurse -Force;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;
Update-Config -Server "" -LoggingActivated -DeactivateCertificateValidationILO;
Set-ConfigPath -Reset;

Get-HWInfoFromILO -ConfigPath "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\prereq\config.json";