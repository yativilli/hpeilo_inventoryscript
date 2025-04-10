. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Functions.ps1

Function Get-DataFromILO {
    param(
        # Array with all the Hostnames of the Servers that will be querried
        [Parameter()]
        [Array]
        $Servers
    )
    try {
        # Get config and login
        $config = Get-Config;
        $login = Get-Content -Path $config.loginConfigPath | ConvertFrom-Json -Depth 2;
        $login.Password = ConvertTo-SecureString -String ($login.Password) -AsPlainText;

        $report = @();
        foreach ($srv in $Servers) {
            Log 6 "Started querying $srv" -IgnoreLogActive

            # Make connection with ILO and save Version.
            $findILO = Find-HPEiLO $srv;
            $iLOVersion = ([regex]"\d").Match($findILO.PN).Value;

            $conn = Connect-HPEiLO -Address $srv -Username $login.Username -Password (ConvertFrom-SecureString -SecureString ($login.Password) -AsPlainText) -DisableCertificateAuthentication:($config.deactivateCertificateValidation) -ErrorAction Stop;

            # Query Powersupply
            Log 6 "`tQuerying PowerSupply" -IgnoreLogActive
            $powerSupply = ($conn | Get-HPEiLOPowerSupply);
            $powerSuppliesDetails = @();
            foreach ($ps in $powerSupply.PowerSupplies) {
                $powerSuppliesDetails += [ordered]@{
                    Serial = $ps.SerialNumber;
                    Status = $iLOVersion -eq 4 ? $ps.Status : $ps.Status.Health;
                    Model  = $ps.Model;
                    Name   = $iLOVersion -eq 4 ? $ps.Label : $ps.Name;
                }
            }
            $powerDetails = @{
                PowerSystemRedundancy = $powerSupply.PowerSupplySummary.PowerSystemRedundancy;
                PresentPowerReading   = $powerSupply.PowerSupplySummary.PresentPowerReading;
                PowerSupplies         = $powerSuppliesDetails;
            }
            
            # Query Processor
            Log 6 "`tQuerying Processor" -IgnoreLogActive
            $processor = ($conn | Get-HPEiLOProcessor).Processor;
            $processorDetails = @();
            foreach ($pr in $processor) {
                $processorDetails += [ordered]@{
                    Model  = $pr.Model;
                    Serial = $pr.SerialNumber;    
                }
            }

            # Query Memory
            Log 6 "`tQuerying Memory" -IgnoreLogActive
            $memory = $iLOVersion -eq 4 ? ($conn | Get-HPEiLOMemoryInfo).MemoryComponent : ($conn | Get-HPEiLOMemoryInfo).MemoryDetails.MemoryData;
            $memoryDetails = @();
            foreach ($me in $memory) {
                $memoryDetails += [ordered]@{
                    Location = $iLOVersion -eq 4 ? $me.MemoryLocation.ToString() : $me.DeviceLocator.ToString();
                    SizeMB   = $iLOVersion -eq 4 ? $me.MemorySizeMB.ToString() : $me.CapacityMiB.ToString();
                    Serial   = $iLOVersion -eq 4 ? "- in ILO4" : $me.SerialNumber;
                }
            }            

            # Query NetworkInterfaces
            Log 6 "`tQuerying NetworkInterfaces" -IgnoreLogActive
            $networkInterfaces = ($conn | Get-HPEiLOServerInfo).NICInfo.EthernetInterface;
            $nicDetails = @();
            foreach ($nic in $networkInterfaces) {
                $nicDetails += [ordered]@{
                    MACAddress    = ([string]$nic.MACAddress).ToLower();
                    Status        = $iLOVersion -eq 4 ? $nic.Status : $nic.Status.State; 
                    InterfaceType = $iLOVersion -eq 4 ? $nic.Location : $nic.InterfaceType;
                }
            }

            # QUery NetworkAdapters
            Log 6 "`tQuerying NetworkAdapters" -IgnoreLogActive
            $networkAdapter = ($conn | Get-HPEiLONICInfo).NetworkAdapter;
            $adapterDetails = @();
            foreach ($na in $networkAdapter) {
                $adapt = @();
                foreach ($neAd in $na.Ports) {
                    $adapt += @{
                        MACAddress = $neAd.MACAddress;
                        Name       = $neAd.Name;
                    }
                }
                $adapterDetails += [ordered]@{
                    Name     = $na.Name;
                    Location = $na.Location;
                    Serial   = $na.SerialNumber;
                    Ports    = $adapt;
                    State    = $iLOVersion -eq 4 ? $na.Status : $na.Status.State;
                }
            }
        
            # Query Devices
            Log 6 "`tQuerying Devices" -IgnoreLogActive
            $devices = ($conn | Get-HPEiLODeviceInventory);
            $deviceDetails = @();
            # Check for Version (function or equivalent does not exist below ILO6)
            if ($iLOVersion -eq 4 -or $iLOVersion -eq 5) { $deviceDetails = $devices.StatusInfo.Message; }else {
                foreach ($dev in $devices.Devices) {
                    $deviceDetails += [ordered]@{
                        Name       = $dev.Name;
                        DeviceType = $dev.DeviceType;
                        Location   = $dev.Location;
                        Serial     = $dev.SerialNumber;
                        Status     = $dev.Status.State;
                    }
                }
            }

            # Query Storage
            Log 6 "`tQuerying Storage" -IgnoreLogActive
            $storageDetails = @();
            # Check for Version (Below and Above ILO 6 handle it differently)
            if (($iLOVersion -eq 4) -or ($iLOVersion -eq 5)) { 
                $storage = ($conn | Get-HPEiLOSmartArrayStorageController).Controllers.PhysicalDrives; 
                foreach ($st in $storage) {
                    $storageDetails += [ordered]@{
                        CapacityGB         = $st.CapacityGB;
                        InterfaceType      = $st.InterfaceType;
                        InterfaceSpeedMbps = $st.InterfaceSpeedMbps;
                        MediaType          = $st.MediaType;
                        Model              = $st.Model;
                        Name               = $st.Name;
                        Serial             = $st.SerialNumber;
                        State              = $st.State;
                    }
                }
            }
            else {
                # Not testable on my configuration
                $storage = ($conn | Get-HPEiLOStorageController -ErrorAction SilentlyContinue).StorageControllers;
                $storageDetails = $storage;
            }
    
            # Query IPv4 Configuration
            Log 6 "`tQuerying IPv4-Configuration" -IgnoreLogActive
            $ipv4 = ($conn | Get-HPEiLOIPv4NetworkSetting);
            $ipv4Details = [ordered]@{
                MACAddress        = $ipv4.MACAddress;
                IPv4Address       = $ipv4.IPv4Address;
                IPv4SubnetMask    = $ipv4.IPv4SubnetMask;
                IPv4Gateway       = $ipv4.IPv4Gateway;
                IPv4AddressOrigin = $ipv4.IPv4AddressOrigin;
                DNSServer         = $ipv4.DNSServer;
                FQDN              = $ipv4.FQDN;
                DomainName        = $ipv4.DomainName;
            };

            # Query IPv6 Configuration
            Log 6 "`tQuerying IPv6-Configuration" -IgnoreLogActive
            $ipv6 = ($conn | Get-HPEiLOIPv6NetworkSetting);
            $ipv6Details = [ordered]@{
                MACAddress        = $ipv6.MACAddress.ToLower();
                IPv6Address       = $ipv6.IPv6Address.Value.ToLower();
                DNSServer         = $ipv6.DNSServer;
                PreferredProtocol = $ipv4.PreferredProtocol;
            };

            # Query Health-Summary
            Log 6 "`tQuerying Health-Summary" -IgnoreLogActive
            $healthSummary = ($conn | Get-HPEiLOHealthSummary);
            $healthDetails = [ordered]@{
                FanStatus           = $healthSummary.FanStatus;
                MemoryStatus        = $healthSummary.MemoryStatus;
                PowerSuppliesStatus = $healthSummary.PowerSuppliesStatus;
                ProcessorStatus     = $healthSummary.ProcessorStatus;
                StorageStatus       = $healthSummary.StorageStatus;
                TemperatureStatus   = $healthSummary.TemperatureStatus;
            }

            # Get MAC 1 to MAC 4 from NetworkAdapters --> to look exactly like Inventory
            Log 6 "`tPrepare MAC 1 - MAC 4" -IgnoreLogActive
            $arr = $networkAdapter.Ports;
            if ($arr.Length -gt 0) {
                $macAddressNotEmbeded = $arr[2..($arr.Length - 1)]
                for ($i = 0; $i -le $macAddressNotEmbeded.Length - 1; $i++) {
                    $macAddress = $macAddressNotEmbeded[$i].MACAddress;
                    switch ($i) {
                        0 { $mac1 = $macAddress; break; }
                        1 { $mac2 = $macAddress; break; }
                        2 { $mac3 = $macAddress; break; }
                        3 { $mac4 = $macAddress; break; }
                        default { $i = ($macAddressNotEmbeded.Length + 1); break; }
                    }
                }
            }            
            
            Log 6 "$srv querrying finished." -IgnoreLogActive

            # Structure Report nicely and add it to array
            $srvReport = [ordered]@{
                Serial            = $findILO.SerialNumber;
                Part_Type_Name    = $conn.TargetInfo.ProductName;
                Hostname          = ($conn | Get-HPEiLOAccessSetting).ServerName.ToLower();
                Hostname_Mgnt     = $conn.Hostname.ToLower();
                MAC_1             = $mac1;
                MAC_2             = $mac2;
                MAC_3             = $mac3;
                MAC_4             = $mac4;
                Mgnt_MAC          = ($conn | Get-HPEiLOIPv4NetworkSetting).PermanentMACAddress.ToLower();
                
                PowerSupply       = $powerDetails;
                
                Health_Summary    = $healthDetails;
                Processor         = $processorDetails
                
                Memory            = $memoryDetails
                NetworkInterfaces = $nicDetails;
                NetworkAdapter    = $adapterDetails;
                Devices           = $deviceDetails;
                Storage           = $storageDetails;

                IPv4Configuration = $ipv4Details;
                IPv6Configuration = $ipv6Details;
            }
            $report += $srvReport;
        }
        # Log Result to Terminal
        Log 3 "Querying ILO finished..."
        Log 3 ($report | ConvertTo-Json -Depth 10) -IgnoreLogActive;

        # Save Result to JSON and CSV-Files
        Log 3 "Begin Saving result in Files"
        Save-DataInJSON $report;
        Save-DataInCSV $report;
    }
    catch {
        $message = $_.Exception.Message.ToString();
        if ($message -match "401") {
            Save-Exception $_ "The ILO-Server $srv returned Unauthorized. Verify that the password in your login.json is correct and you are able to log into the ILO-Interface with it.";
        }
        elseif ($message -match "SSL") {
            Save-Exception $_ "The ILO-Server $srv returned an Error with SSL. Verify that your certificate is properly set or set the flag '-DeactivateCertificateValidationILO'.";    
        }
        else {
            Save-Exception $_ ($_.Exception.Message.ToString());

        }
    }
}

Function Register-Directory {
    <#
    .DESCRIPTION
    Checks the Path that is passed in if it exists and if a file is passed in, it will split the path so that only the Directory is the path
    #>
    param(
        # Path that will be checked if its a directory
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Toggle if the Directory should be generated if it does not exist
        [Parameter()]
        [switch]
        $IgnoreError

    )
    try {
        Log 5 "Check if Directory '$path' exists and create it if needed."
        if ((-not (Test-Path -Path $Path)) -and $IgnoreError) {
            New-Item -Path $Path -Force -ItemType Directory | Out-Null;
        }
        elseif (Test-Path -Path $path) {  
            Log 6 "`tPath $path already exists, now splitting it to return only the directory." 
            $isDirectory = (Get-Item ($Path)) -is [System.IO.DirectoryInfo];
            if (-not $isDirectory) {
                $Path = $Path | Split-Path -Parent -Resolve;
            }
            return $Path.ToString();
        }
        else {
            throw [System.IO.DirectoryNotFoundException] "The directory at '$Path' does not exist. Please verify that the specified path and all its parent folders exist."
        }
        
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Save-DataInJSON {
    param(
        # Report that'll be saved to a report.json
        [Parameter(Mandatory = $true)]
        [Psobject]
        $Report
    )
    try {
        Log 4 "Begin saving results in JSON";
        # Guarantee that a Directory exists at reportPath
        $config = Get-Config;
        $path = $config.reportPath
        Update-Config -ReportPath ((Register-Directory ($path)).ToString()) -LogLevel ($config.logLevel) -DeactivatePingtest:($config.deactivatePingtest) -IgnoreMACAddress:($config.ignoreMACAddress) -IgnoreSerialNumbers:($config.ignoreSerialNumbers) -LogToConsole:($config.logToConsole) -LoggingActivated:($config.loggingActivated) -DoNotSearchInventory:($config.doNotSearchInventory) -DeactivateCertificateValidationILO:($config.deactivateCertificateValidation) ;
        # Save to File with current Date as name
        if (Test-Path -Path ($path)) {
            [string]$date = (Get-Date -Format $DATE_FILENAME).ToString();
            $name = "$path\ilo_report_$date.json";
            Log 6 "`tSave result at $name";
            $report | ConvertTo-Json -Depth 15 | Out-File -FilePath $name -Force;
        }
        else {
            throw [System.IO.DirectoryNotFoundException] "No appropriate path could be find to save the report files. Please verify the specified one exists. The current path is '$path'"
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.ToString());
    }
}

Function Save-DataInCSV {
    param(
        # Report from which the csv-Files will be generated
        [Parameter(Mandatory = $true)]
        [Psobject]
        $Report    
    )

    try {
        # Guarantee that a Directory exists at reportPath
        Log 4 "Begin saving results in CSV"
        $config = Get-Config;
        $generatePath = (Register-Directory ($config.reportPath)).ToString();
        Update-Config -ReportPath $generatePath -LogLevel ($config.logLevel) -DeactivatePingtest:($config.deactivatePingtest) -IgnoreMACAddress:($config.ignoreMACAddress) -IgnoreSerialNumbers:($config.ignoreSerialNumbers) -LogToConsole:($config.logToConsole) -LoggingActivated:($config.loggingActivated) -DoNotSearchInventory:($config.doNotSearchInventory) -DeactivateCertificateValidationILO:($config.deactivateCertificateValidation);
         
        [string]$date = (Get-Date -Format $DATE_FILENAME).ToString();
        $path = $config.reportPath;
    
        if (Test-Path -Path $path) {
            $name = "$path\ilo_report_$date.csv"
            $inventoryData = Get-InventoryData;

            # Save General.csv (like in Inventory)
            Log 6 "`tStart creating the general.csv file at '$name'."
            if ((-not $config.ignoreMACAddress) -or (-not $config.ignoreSerialNumbers)) {

                $csv_report = @();
                foreach ($sr in $Report) {
                    Log 6 "`t`tAdding '$sr' to file."
                    $inventorySrv = $inventoryData | Where-Object -Property "Hostname" -Contains -Value ($sr.Hostname);
                    $csv_report += [ordered]@{
                        Label         = (($inventorySrv | Select-Object -Property "Label").Label).Length -gt 0 ? ($inventorySrv | Select-Object -Property "Label").Label : $NO_VALUE_FOUND_SYMBOL;
                        Hostname      = $sr.Hostname.Length -gt 0 ? $sr.Hostname : $NO_VALUE_FOUND_SYMBOL;
                        Hostname_Mgnt = $sr.Hostname_Mgnt.Length -gt 0 ?  $sr.Hostname_Mgnt : $NO_VALUE_FOUND_SYMBOL;
                        Serial        = $sr.Serial.Length -gt 0 ? $sr.Serial : $NO_VALUE_FOUND_SYMBOL;
                        MAC_1         = $sr.MAC_1.Length -gt 0 ? $sr.MAC_1: $NO_VALUE_FOUND_SYMBOL;
                        MAC_2         = $sr.MAC_2.Length -gt 0 ? $sr.MAC_2 : $NO_VALUE_FOUND_SYMBOL;
                        MAC_3         = $sr.MAC_3.Length -gt 0 ? $sr.MAC_3 : $NO_VALUE_FOUND_SYMBOL;
                        MAC_4         = $sr.MAC_4.Length -gt 0 ? $sr.MAC_4 : $NO_VALUE_FOUND_SYMBOL;
                        Mgnt_MAC      = $sr.Mgnt_MAC.Length -gt 0 ? $sr.Mgnt_MAC : $NO_VALUE_FOUND_SYMBOL;
                    }
                }
                Log 6 "`t`tStart standardizing CSV"
                $csv_report = Get-StandardizedCSV $csv_report;
                $csv_report | ConvertTo-Csv -Delimiter ";" | Out-File -FilePath $name -Force;
            }
        
            # Save MAC.csv (if not deactivated)
            if (-not $config.ignoreMACAddress) {
                $name = "$path\ilo_report_MAC_$date.csv"
                $csv_mac_report = @();
                Log 6 "`tStart creating the macaddress.csv file at '$name'."
                foreach ($sr in $Report) {
                    Log 6 "`t`tAdd $sr to file."
                    $inventorySrv = $inventoryData | Where-Object -Property "Hostname" -Contains -Value ($sr.Hostname);
                    $csv_mac = [ordered]@{
                        Label         = (($inventorySrv | Select-Object -Property "Label").Label).Length -gt 0 ? ($inventorySrv | Select-Object -Property "Label").Label : $NO_VALUE_FOUND_SYMBOL;
                        Hostname      = $sr.Hostname.Length -gt 0 ? $sr.Hostname : $NO_VALUE_FOUND_SYMBOL;
                        Hostname_Mgnt = $sr.Hostname_Mgnt.Length -gt 0 ?  $sr.Hostname_Mgnt : $NO_VALUE_FOUND_SYMBOL;
                        Mgnt_MAC      = $sr.Mgnt_MAC.Length -gt 0 ? $sr.Mgnt_MAC : $NO_VALUE_FOUND_SYMBOL;
                    }   

                    Log 6 "`t`t`tAdd NetworkInterfaces to file."
                    [int]$i = 1;
                    foreach ($nic in $sr.NetworkInterfaces) {
                        $nic.MACAddress = $nic.MACAddress.Length -gt 0 ? $nic.MACAddress : $NO_VALUE_FOUND_SYMBOL;
                        $csv_mac.Add(("NetInterf_MAC_$i"), $nic.MACAddress);
                        $i++;
                    }

                    $i = 1
                    Log 6 "`t`t`tAdd NetworkAdapters to file."
                    foreach ($nad in $sr.NetworkAdapter) {
                        foreach ($p in $nad.Ports) {
                            $p.MACAddress = $p.MACAddress.Length -gt 0 ? $p.MACAddress : $NO_VALUE_FOUND_SYMBOL;
                            $csv_mac.Add(("NetAdap_MAC_$i"), $p.MACAddress);   
                            $i++; 
                        }
                    }
        
                    $csv_mac_report += $csv_mac
                }
                Log 6 "`t`tStart standardizing CSV"
                $csv_mac_report = Get-StandardizedCSV $csv_mac_report;
                $csv_mac_report | Export-Csv -Path $name -Delimiter ";" -Force;
            }

            # Save SerialNumber.csv (if not deactivated) -- long because it must be mapped as simple as possible from a very nested structure
            if (-not $config.ignoreSerialNumbers) {
                $name = "$path\ilo_report_SERIAL_$date.csv"
                Log 6 "`tStart creating the serialnumbers.csv file at '$name'."
                $csv_serial_report = @();
                $csv_additional_info = @();
                foreach ($sr in $Report) {
                    Log 6 "`t`tAdd $sr to file."
                    $inventorySrv = $inventoryData | Where-Object -Property "Hostname" -Contains -Value ($sr.Hostname);
                    $csv_serial = [ordered]@{
                        Label         = (($inventorySrv | Select-Object -Property "Label").Label).Length -gt 0 ? ($inventorySrv | Select-Object -Property "Label").Label : "";
                        Hostname      = $sr.Hostname.Length -gt 0 ? $sr.Hostname : $NO_VALUE_FOUND_SYMBOL;
                        Hostname_Mgnt = $sr.Hostname_Mgnt.Length -gt 0 ?  $sr.Hostname_Mgnt : $NO_VALUE_FOUND_SYMBOL;
                        Serial        = $sr.Serial.Length -gt 0 ? $sr.Serial : $NO_VALUE_FOUND_SYMBOL;
                    }   
                    $csv_additional = [ordered]@{
                        Label         = (($inventorySrv | Select-Object -Property "Label").Label).Length -gt 0 ? ($inventorySrv | Select-Object -Property "Label").Label : "";
                        Hostname      = $sr.Hostname.Length -gt 0 ? $sr.Hostname : $NO_VALUE_FOUND_SYMBOL;
                        Hostname_Mgnt = $sr.Hostname_Mgnt.Length -gt 0 ?  $sr.Hostname_Mgnt : $NO_VALUE_FOUND_SYMBOL;
                        Serial        = $sr.Serial.Length -gt 0 ? $sr.Serial : $NO_VALUE_FOUND_SYMBOL;
                    };

                    Log 6 "`t`t`tAdding Powersupplies to file"
                    [int]$i = 1;
                    $pwr = $sr.PowerSupply.PowerSupplies;
                    foreach ($ps in $pwr) {
                        $ps.Serial = $ps.Serial.Length -gt 0 ? $ps.Serial : $NO_VALUE_FOUND_SYMBOL;
                        $csv_serial.Add(("PowerSupply$i"), $ps.Serial);
                        $csv_additional.Add(("PowerSupply_$i"), $ps.Name);
                        $i++;
                    }
        
                    Log 6 "`t`t`tAdding Processors to file"
                    $i = 1;
                    foreach ($pr in $sr.Processor) {
                        $pr.Serial = $pr.Serial.Length -gt 0 ? $pr.Serial : $NO_VALUE_FOUND_SYMBOL;
                        $csv_serial.Add(("Processor$i"), $pr.Serial);
                        $csv_additional.Add(("Processor_$i"), $pr.Model);
                        $i++;
                    }

                    Log 6 "`t`t`tAdding Devices to file"
                    $i = 1;
                    foreach ($dev in $sr.Devices) {
                        if ($iLOVersion -gt 5 -and (-not (($dev -match "supported")))) {
                            $dev.Serial = $dev.Serial.Length -gt 0 ? $dev.Serial : $NO_VALUE_FOUND_SYMBOL;
                            $csv_serial.Add(("Device$i"), $dev.Serial);
                            $csv_additional.Add(("Device_$i"), $dev.Name);
                            $i++;
                        }
                    }

                    Log 6 "`t`t`tAdding Storage to file"
                    $i = 1;
                    foreach ($stor in $sr.Storage) {
                        if ($iLOVersion -lt 6) {
                            $stor.Serial = $stor.Serial.Length -gt 0 ? $stor.Serial : $NO_VALUE_FOUND_SYMBOL;
                            $csv_serial.Add(("Storage$i"), $stor.Serial);
                            $csv_additional.Add(("Storage_$i"), $stor.Name + "," + $stor.Model);
                            $i++;
                        }
                    }

                    Log 6 "`t`t`tAdding Memory to file"
                    $i = 1;
                    foreach ($mem in $sr.Memory) {
                        $mem.Serial = $mem.Serial.Length -gt 0 ? $mem.Serial : $NO_VALUE_FOUND_SYMBOL;
                        $csv_serial.Add(("Memory$i"), $mem.Serial)
                        $csv_additional.Add(("Memory_$i"), $mem.Location)
                        $i++;
                    }
                    $csv_additional_info += $csv_additional;
                    $csv_serial_report += $csv_serial;
                }

                Log 6 "`t`tStart standardizing serialnumbers CSV"
                $csv_serial_report = Get-StandardizedCSV $csv_serial_report;
                $csv_serial_report | Export-Csv -Path $name -Delimiter ";" -Force;

                # Add Name and location below serialnumbers to make it easier to know which means which
                Add-Content -Path $name -Value "`r`n`n`n`nAdditional Information for above;"
                $csv_additional_info = Get-StandardizedCSV $csv_additional_info; 
                $csv_additional_info | ConvertTo-Csv -Delimiter ";" | Add-Content -Path $name -Force
            }
        }
        else {
            throw [System.IO.DirectoryNotFoundException] "No appropriate path could be find to save the report files. Please verify the specified one exists. The current path is '$path'"
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Get-StandardizedCSV {
    param(
        # Object, in which all Members will be standardized to exist.
        [Parameter(Mandatory = $true)]
        $Report
    )
    try {
        # Guarantee that all Keys used in the entire array of objects exist on all - otherwise csv has a problem with displaying all of them
        Log 5 "Standardizing Keys across array of object passed in."
        $unique = $Report | ForEach-Object { $_.Keys } | Select-Object -Unique
        foreach ($srvObj in $Report) {
            foreach ($uniqueMember in $unique) {
                if (($srvObj.Keys -contains $uniqueMember) -eq $false) {    
                    $srvObj | Add-Member -Name $uniqueMember -Value $NO_VALUE_FOUND_SYMBOL -MemberType NoteProperty;
                }
            }
        }
        return $Report;
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Get-InventoryData {
    try {
        # Return Inventorydata from previously saved file.
        $config = Get-Config;
        $path = $config.searchForFilesAt + "\inventory_results.json";
        Log 5 "Import Inventory Data from '$path'"
        if (Test-Path -Path $path) {
            $server = Get-Content $path | ConvertFrom-Json -Depth 10;
        }
    }
    catch [System.IO.FileNotFoundException], [System.IO.DirectoryNotFoundException] {
        Save-Exception $_ "The file $path does not exist or has been moved. Do not move or delete, as it is vital to query from Inventory.";
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
    return $server;
}