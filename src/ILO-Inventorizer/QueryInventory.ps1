. $PSScriptRoot\General_Functions.ps1
. $PSScriptRoot\Configuration_Functions.ps1

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
        }   

        # Check if Inventory is configured to be querried and execute a Pingtest.
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

                # Requesting Data from Inventory and save it in a file.
                Log 6 "`tSending REST-Request to Inventory"
                $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -HttpVersion 3.0
                Invoke-InventoryResponseCleaner -Response $resp;
                
            }
            # Inventory not found with Pingtest
            else {
                throw [System.Net.WebException] "Inventory.psi.ch is not reachable - verify that it's reachable from your network. If not, set 'doNotSearchInventory' to false and add the Servers manually with PS> Get-HWInfoFromILO -server @('Hostname1', 'Hostname2') ";
            }
        }
        return $false;
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Invoke-InventoryResponseCleaner {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]
        $Response
    )
    if ($null -ne $Response) {
        $config = Get-Config;

        $servers = (($Response).d.Rows);
        $names = (($Response).d.Columns);
        $serversClean = @();
        foreach ($srv in $servers) {
            $serversClean += [ordered]@{
                $names[0]  = $srv[0]
                $names[1]  = $srv[1]
                $names[2]  = $srv[2]
                $names[3]  = $srv[3]
                $names[4]  = $srv[4]
                $names[5]  = $srv[5]
                $names[6]  = $srv[6]
                $names[7]  = $srv[7]
                $names[8]  = $srv[8]
                $names[9]  = $srv[9]
                $names[10] = $srv[10]
                $names[11] = $srv[11]
                $names[12] = $srv[12]
            }
        }
        Log 6 "`tFilter Inventory-Answer for servers"
        $serversClean = $serversClean | Where-Object -Property "Label" -match "SRV*";

        Register-Directory ($config.searchForFilesAt);
        $serversClean | ConvertTo-Json -Depth 3 | Out-File -Path ($config.searchForFilesAt + "\inventory_results.json");
        
        # Save Servers if a Mgnt-Hostname exists.
        [Array]$serversToSave = @();
        Log 6 "`tSaving servers in json if a Hostname_Mgnt exists."
        if ($config.remoteMgmntField.Length -le 0) {
            throw [System.IO.InvalidDataException] "The field 'RemoteMgntField' cannot be zero. Please verify that your config includes a value like 'Hostname Mgnt'"
        }

        foreach ($s in $serversClean) {
            if ($s["$($config.remoteMgmntField)"].Length -gt 0) {
                $serversToSave += $s["$($config.remoteMgmntField)"];
            }
        }

        Save-ServersFromInventory -ServersToSave $serversToSave;
    }
}

Function Save-ServersFromInventory {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [array]
        $ServersToSave
    )
    if ($null -ne $ServersToSave) {
        $config = Get-Config;
        # Handle Saving to file
        Log 6 "`tSave servers into file and update the configuration."
        # Create New Path
        if ($config.serverPath.Length -eq 0) {
            $generateServerPath = $config.searchForFilesAt + "\server.json"
            New-File ($generateServerPath);
            $config = Get-Config;
            Update-Config -ServerPath $generateServerPath -LogLevel ($config.logLevel) -DeactivatePingtest:($config.deactivatePingtest) -IgnoreMACAddress:($config.ignoreMACAddress) -IgnoreSerialNumbers:($config.ignoreSerialNumbers) -LogToConsole:($config.logToConsole) -LoggingActivated:($config.loggingActivated) -DoNotSearchInventory:($config.doNotSearchInventory) -DeactivateCertificateValidationILO:($config.deactivateCertificateValidation);
        }
        $config = Get-Config;
        # Add to Existing path
        if (Test-Path -Path $config.serverPath) {
            [pscustomobject[]]$servers = Get-Content $config.serverPath | ConvertFrom-Json;
            foreach ($srv in $ServersToSave) {
                $servers += ($srv);
            }
            $servers | ConvertTo-Json -Depth 2 | Out-File -Path ($config.serverPath);
        }
        # Path does not Exist
        else {
            $Path = $config.serverPath;
            throw [System.IO.FileNotFoundException] "The server-path at '$Path' could not be found. Please verify that the file exists."
        }
    }
}