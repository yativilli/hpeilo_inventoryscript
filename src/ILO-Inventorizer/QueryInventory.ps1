. .\ILO-Inventorizer\Functions.ps1

Function Get-ServersFromInventory {
    param()
    
    $config = Get-Config;
    $config;

    $DoNotSearchInventory = $config.doNotSearchInventory;
    $SearchStringInventory = $config.searchStringInventory;
    $RemoteMgmntField = $config.remoteMgmntField;

    $InventoryReachable = Invoke-PingTest -Hostname inventory.psi.ch;
    if ((-not $DoNotSearchInventory) -and $InventoryReachable) {
        Write-Host "$RemoteMgmntField";
        
        $uri = "https://inventory.psi.ch/DataAccess.asmx/FindObjects";
        $headers = @{"Content-Type" = "application/json; charset= utf-8" };
        $body = @{
            "search" = @{
                "query" = @(@{
                        "Field"    = "ANY"
                        "Operator" = "Contains"
                        "Value"    = $SearchStringInventory
                    })
                "columns"= @(
                    "Label",
                    "Hostname",
                    $RemoteMgmntField
                )
            }
        } | ConvertTo-Json -Depth 4

        $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -HttpVersion 3.0
        Write-Host (($resp).d.Rows | ConvertTo-Json -Depth 2);

        return $true;
    }
    else {
        return $false;
    }
}