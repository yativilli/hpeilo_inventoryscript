Remove-Item -Path "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\dump\*" -Recurse -Force;
Remove-Item -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\*" -Recurse -Force;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;
Set-ConfigPath -Reset;

Get-HWInfoFromILO -SearchStringInventory "gfa-sioc-cs-de" -Username "Yannik" -Password (ConvertTo-SecureString -String "test!1234" -AsPlainText) -LogLevel 5 -LoggingActivated -DeactivateCertificateValidationILO -ReportPath "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\dump\" -LogPath "U:\IPA\IPA\IPA_Sourcecode_hpeilo_inventoryscript\src\demonstration\dump\" -;