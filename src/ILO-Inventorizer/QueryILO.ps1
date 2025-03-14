. .\ILO-Inventorizer\Constants.ps1
. .\ILO-Inventorizer\Functions.ps1

Function Get-DataFromILO {
    param(
        [Parameter()]
        [Array]
        $servers
    )
    try {
        $config = Get-Config;
        $login = Get-Content -Path $config.loginConfigPath | ConvertFrom-Json -Depth 2;

        $report = @();
        foreach ($srv in $servers) {
            Log 6 "Started querying $srv" -IgnoreLogActive

            $findILO = Find-HPEiLO $srv;
            $iLOVersion = ([regex]"\d").Match($findILO.PN).Value;
            $conn = Connect-HPEiLO -Address $srv -Username $login.Username -Password $login.Password -DisableCertificateAuthentication:($config.deactivateCertificateValidation);

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
            
            Log 6 "`tQuerying Processor" -IgnoreLogActive
            $processor = ($conn | Get-HPEiLOProcessor).Processor;
            $processorDetails = @();
            foreach ($pr in $processor) {
                $processorDetails += [ordered]@{
                    Model  = $pr.Model;
                    Serial = $pr.SerialNumber;    
                }
            }

            Log 6 "`tQuerying Memory" -IgnoreLogActive
            $memory = $iLOVersion -eq 4 ? ($conn | Get-HPEiLOMemoryInfo).MemoryComponent : ($conn | Get-HPEiLOMemoryInfo).MemoryDetails.MemoryData;
            $memoryDetails = @();
            foreach ($me in $memory) {
                $memoryDetails += [ordered]@{
                    Location = $iLOVersion -eq 4 ? $me.MemoryLocation.ToString() : $me.DeviceLocator.ToString();
                    SizeMB   = $iLOVersion -eq 4 ? $me.MemorySizeMB.ToString() : $me.CapacityMiB.ToString();
                }
            }            

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
        

            Log 6 "`tQuerying Devices" -IgnoreLogActive
            $devices = ($conn | Get-HPEiLODeviceInventory);
            $deviceDetails = @();
            if ($iLOVersion -eq 4) { $deviceDetails = $devices.StatusInfo.Message; }else {
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

            Log 6 "`tQuerying Storage" -IgnoreLogActive
            $storageDetails = @();
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


            Log 6 "`tQuerying IPv6-Configuration" -IgnoreLogActive
            $ipv6 = ($conn | Get-HPEiLOIPv6NetworkSetting);
            $ipv6Details = [ordered]@{
                MACAddress        = $ipv6.MACAddress.ToLower();
                IPv6Address       = $ipv6.IPv6Address.Value.ToLower();
                DNSServer         = $ipv6.DNSServer;
                PreferredProtocol = $ipv4.PreferredProtocol;
            };

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
        Log 0 "Ended"
        Log 0 ($report | ConvertTo-Json -Depth 10) -IgnoreLogActive;

        Save-DataInJSON $report;
    }
    catch {
        Write-Error $_;
    }
}

Function Guarantee-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force -ItemType Directory;
    }

    $isDirectory = (Get-Item ($Path)) -is [System.IO.DirectoryInfo];
    if (-not $isDirectory) {
        $Path = $Path | Split-Path -Parent -Resolve;
    }
}

Function Save-DataInJSON {
    param(
        [Parameter(Mandatory = $true)]
        [Psobject]
        $Report
    )

    $config = Get-Config;
    (Guarantee-Directory ($config.reportPath));
    [string]$date = (Get-Date -Format "yyyy_MM_dd").ToString();
    $path = $config.reportPath
    $name = "$path\ilo_report_$date.json";
    $report | ConvertTo-Json -Depth 15 | Out-File -FilePath $name -Force;
}

Function Save-DataInCSV {
    param(
        [Parameter(Mandatory = $true)]
        [Psobject]
        $Report    
    )

    $config = Get-Config;
    (Guarantee-Directory ($config.reportPath));
    [string]$date = (Get-Date -Format "yyyy_MM_dd").ToString();
    $path = $config.reportPath
    
    # General (like in Inventory)
    $name = "$path\result_$date.csv"
    $inventoryData = Get-InventoryData;

    $csv_report = @();
    foreach ($sr in $Report) {
        $inventorySrv = $inventoryData | Where-Object -Property "Hostname" -Contains -Value ($sr.Hostname);
        $csv_report += [ordered]@{
            Label         = (($inventorySrv | Select-Object -Property "Label").Label).Length -gt 0 ? ($inventorySrv | Select-Object -Property "Label").Label : "";
            Hostname      = $sr.Hostname.Length -gt 0 ? $sr.Hostname : "";
            Hostname_Mgnt = $sr.Hostname_Mgnt.Length -gt 0 ?  $sr.Hostname_Mgnt : "";
            Serial        = $sr.Serial.Length -gt 0 ? $sr.Serial : "";
            MAC_1         = $sr.MAC_1.Length -gt 0 ? $sr.MAC_1: "";
            MAC_2         = $sr.MAC_2.Length -gt 0 ? $sr.MAC_2 : "";
            MAC_3         = $sr.MAC_3.Length -gt 0 ? $sr.MAC_3 : "";
            MAC_4         = $sr.MAC_4.Length -gt 0 ? $sr.MAC_4 : "";
            Mgnt_MAC      = $sr.Mgnt_MAC.Length -gt 0 ? $sr.Mgnt_MAC : "";
        }
    }
    $csv_report | ConvertTo-Csv -Delimiter ";" | Out-File -FilePath $name -Force;

    # MAC (if not deactivated)
    $name = "$path\result_$date.csv"
    #  $report | ConvertTo-Csv -Delimiter ";" | Out-File -FilePath $name -Force;

    # SerialNumber (if not deactivated)
    $name = "$path\result_$date.csv"
    # $report | ConvertTo-Csv -Delimiter ";" | Out-File -FilePath $name -Force;
}

Function Get-InventoryData {
    $config = Get-Config;
    $path = $config.searchForFilesAt + "\inventory_results.json";
    $server = Get-Content $path | ConvertFrom-Json -Depth 10;
    return $server;
}