Remove-Module ILO-Inventorizer;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;
# Get-DataFromILO -servers @("rmgfa-sioc-cs-de4") #, "rmgfa-sioc-cs-de4", "rmgfa-sioc-cs-de3", "rmdl20test");
# Save-DataInJSON @("rmgfa-sioc", "rmsf-sioc-cs");

Save-DataInCSV (Get-Content -Path "C:\Users\wernle_y\AppData\Roaming\hpeilo\out\ilo_report_2025_03_14.json" | ConvertFrom-Json -Depth 10);