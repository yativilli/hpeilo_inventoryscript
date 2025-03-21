. $PSScriptRoot\Functions.ps1

Function Get-ServersFromInventory { 
    try {
        Log 5 "Starting process to get servers from Inventory"
        $config = Get-Config;
        $doNotSearchInventory = $config.doNotSearchInventory;
        $searchStringInventory = $config.searchStringInventory;
        $remoteMgmntField = $config.remoteMgmntField;
        
        # Check if it matches naming convention
        Log 6 "`tValidate naming convention before querying inventory"
        [regex]$reg = '(gfa)?(s(f)?(ls)?)?-.*';
        $doesMatchNamingConvention = $reg.Match($searchStringInventory).Success;
        if (-not $doesMatchNamingConvention) {
            throw [System.Text.RegularExpressions.RegexParseException] "The search string does not match the naming convention. The search String must contain something like 'gfa-', 'sf-', 'sls-'.";
            return $false;
        }   

        if ((-not $doNotSearchInventory)) {
            $inventoryReachable = Invoke-PingTest -Hostname inventory.psi.ch;
            Log 6 "`tChecking if inventory is reachable: $inventoryReachable";
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

                Log 6 "`tSending REST-Request to Inventory"
                $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -HttpVersion 3.0
                $servers = (($resp).d.Rows);
                $serversClean = @();
                foreach ($srv in $servers) {
                    $serversClean += [ordered]@{
                        Label         = $srv[0]
                        Hostname      = $srv[1]
                        Hostname_Mgnt = $srv[2]
                        Serial        = $srv[3]
                        Part_Type     = $srv[4]
                        Facility      = $srv[5]
                        MAC_1         = $srv[6]
                        MAC_2         = $srv[7]
                        MAC_3         = $srv[8]
                        MAC_4         = $srv[9]
                        Mgnt_MAC      = $srv[10]
                        HW_Status     = $srv[11]
                        OS            = $srv[12]
                    }
                }
                Log 6 "`tFilter Inventory-Answer for servers"
                $serversClean = $serversClean | Where-Object -Property "Label" -match "SRV*";

                Register-Directory ($config.searchForFilesAt);
                $serversClean | ConvertTo-Json -Depth 3 | Out-File -Path ($config.searchForFilesAt + "\inventory_results.json");
        
                # Save Servers in server.json
                [Array]$serversToSave = @();
                Log 6 "`tSaving servers in json if a Hostname_Mgnt exists."
                foreach ($s in $serversClean) {
                    if ($s.Hostname_Mgnt.Length -gt 0) {
                        $serversToSave += $s.Hostname_Mgnt;
                    }
                }

                Log 6 "`tSave servers into file and update the configuration."
                # No Server Path found - generate new one.
                if ($config.serverPath.Length -eq 0) {
                    $generateServerPath = $config.searchForFilesAt + "\server.json"
                    New-File ($generateServerPath);
                    $config = Get-Config;
                    Update-Config -ServerPath $generateServerPath -LogLevel ($config.logLevel) -DeactivatePingtest:($config.deactivatePingtest) -IgnoreMACAddress:($config.ignoreMACAddress) -IgnoreSerialNumbers:($config.ignoreSerialNumbers) -LogToConsole:($config.logToConsole) -LoggingActivated:($config.loggingActivated) -DoNotSearchInventory:($config.doNotSearchInventory) -DeactivateCertificateValidationILO:($config.deactivateCertificateValidation);
                }
                $config = Get-Config;
                if (Test-Path -Path $config.serverPath) {
                    $serversToSave | ConvertTo-Json -Depth 2 | Out-File -Path ($config.serverPath);
                }
                else {
                    $Path = $config.serverPath;
                    throw [System.IO.FileNotFoundException] "The file at '$Path' could not be found. Please verify that the file exists."
                }
            }
            # Inventory not found with Pingtest
            else {
                throw [System.Net.WebException] "Inventory.psi.ch is not reachable - verify that it's reachable from your network. If not, set 'doNotSearchInventory' to false and add the Servers manually with PS> Get-HWInfoFromILO -server @('Hostname1', 'Hostname2') ";
            }
        }
        return $false;
        #>   
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}