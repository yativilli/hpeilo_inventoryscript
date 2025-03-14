Remove-Module ILO-Inventorizer;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;
# Get-HWInfoFromILO;
# Save-DataInJSON @("rmgfa-sioc", "rmsf-sioc-cs");

Save-DataInCSV (Get-Content -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\out\ilo_report_2025_03_14.json" | ConvertFrom-Json -Depth 10);
# Get-InventoryData;