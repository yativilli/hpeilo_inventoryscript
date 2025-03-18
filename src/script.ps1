Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;

Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

# Save-DataInCSV (Get-Content -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\ilo_report_2025_03_17_stor.json" | ConvertFrom-Json -Depth 10);
# Get-NewConfig
Set-PSDebug -Trace 0
Get-HWInfoFromILO -ServerPath C:\Users\wernle_y\Downloads\server.json -Password (ConvertTo-SecureString -String "test!1234" -AsPlainText) -Username "Yannik" -DeactivateCertificateValidationILO