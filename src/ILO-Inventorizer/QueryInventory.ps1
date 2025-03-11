. .\ILO-Inventorizer\Functions.ps1

Function Get-ServersFromInventory {
    param()
    
    $config = Get-Config;

    $doNotSearchInventory = $config.doNotSearchInventory;
    $searchStringInventory = $config.searchStringInventory;
    $remoteMgmntField = $config.remoteMgmntField;
    
    # Check if it matches naming convention
    [regex]$reg = '(gfa)?(s(f)?(ls)?)?-.*';
    $doesMatchNamingConvention = $reg.Match($searchStringInventory).Success;
    if (-not $doesMatchNamingConvention) {
        throw [System.Text.RegularExpressions.RegexParseException] "The search string does not match the naming convention. The search String must contain something like 'gfa-', 'sf-', 'sls-'.";
        return $false;
    }   

    if ((-not $doNotSearchInventory)) {
        $inventoryReachable = Invoke-PingTest -Hostname inventory.psi.ch;
        if ($inventoryReachable) {
            # Query Inventory        
            $uri = "https://inventory.psi.ch/DataAccess.asmx/FindObjects";
            $headers = @{"Content-Type" = "application/json; charset= utf-8" };
            $body = @{
                "search" = @{
                    "query"   = @(@{
                            "Field"    = "ANY"
                            "Operator" = "Contains"
                            "Value"    = $searchStringInventory
                        })
                    "columns" = @(
                        "Label",
                        "Hostname",
                        $remoteMgmntField,
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

            $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -HttpVersion 3.0
            $servers = (($resp).d.Rows);

            $servers | ConvertTo-Json -Depth 3 | Out-File -Path ($config.searchForFilesAt + "\inventory_results.json");
        
            # Save Servers in server.json
            [Array]$serversToSave = @();
            foreach ($s in $servers) {
                $psiLabel = $s[0];
                $hostnameMgnt = $s[2];
                Write-Host $s[2];
                if ($hostnameMgnt.Length -gt 0) {
                    $serversToSave += $hostnameMgnt;
                }
            }

            # No Server Path found - generate new one.
            if ($config.serverPath.Length -eq 0) {
                $generateServerPath = $config.searchForFilesAt + "\server.json"
                New-File ($generateServerPath);
                Update-Config -ServerPath $generateServerPath;
                $config = Get-Config;
            }
      
            if (Test-Path -Path $config.serverPath) {
                $serversToSave | ConvertTo-Json -Depth 2 | Out-File -Path ($config.serverPath);
                Write-Host ($servers.Length, $serversToSave.Length);
                return $true;
            }
            else {
                $Path = $config.serverPath;
                throw [System.IO.FileNotFoundException] "The file at '$Path' could not be found. Please verify that the file exists."
            }
        }
        # Inventory not found with Pingtest
        else {
            throw [System.Net.WebException] "Inventory.psi.ch is not reachable";
        }
    }
    return $false;
    #>

}