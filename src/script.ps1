Remove-Module ILO-Inventorizer;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;
Set-PSDebug -Trace 0

# Save-DataInCSV (Get-Content -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\ilo_report_2025_03_17_stor.json" | ConvertFrom-Json -Depth 10);
# Get-NewConfig

[securestring]$s = ConvertTo-SecureString -String ("test!1234") -AsPlainText -Force;
$str = $s | ConvertFrom-SecureString -AsPlainText
$str
$conn = Connect-HPEiLO -Address rmgfa-sioc-cs-dev -Username "Yannik" -Password $str -DisableCertificateAuthentication;
$conn