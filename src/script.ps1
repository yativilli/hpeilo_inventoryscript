Remove-Module ILO-Inventorizer;
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Get-HWInfoFromILO -configPath "U:\IPA\config.json" -LogPath "U:\IPA\logs" -LoggingActivated;