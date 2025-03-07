Remove-Module ILO-Inventorizer;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Generate-Config -Path "U:\IPA" -NotEmpty -WithOutInventory;