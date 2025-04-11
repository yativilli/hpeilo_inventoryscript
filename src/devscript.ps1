Remove-Module ILO-Inventorizer;
Remove-Module HPEiLOCmdlets;

Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Set-PSDebug -Trace 0

$uri = "https://inventory.psi.ch/DataAccess.asmx/FindObjects";
$headers = @{"Content-Type" = "application/json; charset= utf-8" };
$body = @{
    "search" = @{
        "query"   = @(@{
                "Field"    = "ANY"
                "Operator" = "Contains"
                "Value"    = "sf-sioc-cs-"
            })
        "columns" = @(
            "Label",
            "Hostname",
            "Hostname Mgnt",
            "Serial",
            "Part Type",
            "Facility",
            "MAC 1",
            "MAC 2",
            "MAC 3",
            "MAC 4",
            "Mgnt MAC",
            "HW Status",
            "OS"
        )
    }
} | ConvertTo-Json -Depth 4

# Requesting Data from Inventory and save it in a file.
Log 6 "`tSending REST-Request to Inventory"
$resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -HttpVersion 3.0
Invoke-InventoryResponseCleaner -Response $resp;