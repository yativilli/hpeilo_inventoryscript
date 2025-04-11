. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\General_Functions.ps1

### QUERYING FROM ILO
Function Get-PowerSupplyData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # Query Powersupply
        Log 6 "`tQuerying PowerSupply" -IgnoreLogActive
        $powerSupply = ($Connection | Get-HPEiLOPowerSupply);
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
        return $powerDetails;
    }
}

Function Get-ProcessorData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # Query Processor
        Log 6 "`tQuerying Processor" -IgnoreLogActive
        $processor = ($Connection | Get-HPEiLOProcessor).Processor;
        $processorDetails = @();
        foreach ($pr in $processor) {
            $processorDetails += [ordered]@{
                Model  = $pr.Model;
                Serial = $pr.SerialNumber;    
            }
        }
        return $processorDetails;
    }
}

Function Get-MemoryData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # Query Memory
        Log 6 "`tQuerying Memory" -IgnoreLogActive
        $memory = $iLOVersion -eq 4 ? ($Connection | Get-HPEiLOMemoryInfo).MemoryComponent : ($Connection | Get-HPEiLOMemoryInfo).MemoryDetails.MemoryData;
        $memoryDetails = @();
        foreach ($me in $memory) {
            $memoryDetails += [ordered]@{
                Location = $iLOVersion -eq 4 ? $me.MemoryLocation.ToString() : $me.DeviceLocator.ToString();
                SizeMB   = $iLOVersion -eq 4 ? $me.MemorySizeMB.ToString() : $me.CapacityMiB.ToString();
                Serial   = $iLOVersion -eq 4 ? "- in ILO4" : $me.SerialNumber;
            }
        }   
        return $memoryDetails;
    }
}

Function Get-NICData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # Query NetworkInterfaces
        Log 6 "`tQuerying NetworkInterfaces" -IgnoreLogActive
        $networkInterfaces = ($Connection | Get-HPEiLOServerInfo).NICInfo.EthernetInterface;
        $nicDetails = @();
        foreach ($nic in $networkInterfaces) {
            $nicDetails += [ordered]@{
                MACAddress    = ([string]$nic.MACAddress).ToLower();
                Status        = $iLOVersion -eq 4 ? $nic.Status : $nic.Status.State; 
                InterfaceType = $iLOVersion -eq 4 ? $nic.Location : $nic.InterfaceType;
            }
        }
        return $nicDetails;
    }
}

Function Get-NetAdapterData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # QUery NetworkAdapters
        Log 6 "`tQuerying NetworkAdapters" -IgnoreLogActive
        $networkAdapter = ($Connection | Get-HPEiLONICInfo).NetworkAdapter;
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
        return $adapterDetails;
    }
}

Function Get-DeviceData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # Query Devices
        Log 6 "`tQuerying Devices" -IgnoreLogActive
        $devices = ($Connection | Get-HPEiLODeviceInventory);
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
        return $deviceDetails;
    }
}

Function Get-StorageData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # Query Storage
        Log 6 "`tQuerying Storage" -IgnoreLogActive
        $storageDetails = @();
        # Check for Version (Below and Above ILO 6 handle it differently)
        if (($iLOVersion -eq 4) -or ($iLOVersion -eq 5)) { 
            $storage = ($Connection | Get-HPEiLOSmartArrayStorageController).Controllers.PhysicalDrives; 
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
            $storage = ($Connection | Get-HPEiLOStorageController -ErrorAction SilentlyContinue).StorageControllers;
            $storageDetails = $storage;
        }
        return $storageDetails;
    }
}

Function Get-IPv4Data {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # Query IPv4 Configuration
        Log 6 "`tQuerying IPv4-Configuration" -IgnoreLogActive
        $ipv4 = ($Connection | Get-HPEiLOIPv4NetworkSetting);
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
        return $ipv4Details;
    }
}

Function Get-IPv6Data {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # Query IPv6 Configuration
        Log 6 "`tQuerying IPv6-Configuration" -IgnoreLogActive
        $ipv6 = ($Connection | Get-HPEiLOIPv6NetworkSetting);
        $ipv6Details = [ordered]@{
            MACAddress        = $ipv6.MACAddress.ToLower();
            IPv6Address       = $ipv6.IPv6Address.Value.ToLower();
            DNSServer         = $ipv6.DNSServer;
            PreferredProtocol = $ipv4.PreferredProtocol;
        };
        return $ipv6Details;
    }
}

Function Get-HealthSummaryData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        # Query Health-Summary
        Log 6 "`tQuerying Health-Summary" -IgnoreLogActive
        $healthSummary = ($Connection | Get-HPEiLOHealthSummary);
        $healthDetails = [ordered]@{
            FanStatus           = $healthSummary.FanStatus;
            MemoryStatus        = $healthSummary.MemoryStatus;
            PowerSuppliesStatus = $healthSummary.PowerSuppliesStatus;
            ProcessorStatus     = $healthSummary.ProcessorStatus;
            StorageStatus       = $healthSummary.StorageStatus;
            TemperatureStatus   = $healthSummary.TemperatureStatus;
        }
        return $healthDetails
    }
}

Function Format-MACAddressesLikeInventory {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Connection
    )
    if ($null -ne $Connection) {
        $macs = @{
            MAC1 = "";
            MAC2 = "";
            MAC3 = "";
            MAC4 = "";
        }
        $ports = $networkAdapter.Ports;
        if ($ports.Length -gt 0) {
            $macAddressNotEmbeded = $ports[2..($ports.Length - 1)]
            for ($i = 0; $i -le $macAddressNotEmbeded.Length - 1; $i++) {
                $macAddress = $macAddressNotEmbeded[$i].MACAddress;
                switch ($i) {
                    0 { $macs.MAC1 = $macAddress; break; }
                    1 { $macs.MAC2 = $macAddress; break; }
                    2 { $macs.MAC3 = $macAddress; break; }
                    3 { $macs.MAC4 = $macAddress; break; }
                    default { $i = ($macAddressNotEmbeded.Length + 1); break; }
                }
            }
        }     
        return $macs;
    }
}

#### SAVING TO FILES
Function Save-GeneralInformationToCSV {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $Report
    )
    if ($null -ne $Report) {
        [string]$date = (Get-Date -Format $DATE_FILENAME).ToString();
        $config = Get-Config;
        $name = "$path\ilo_report_$date.csv"
        $path = $config.reportPath;
        $inventoryData = Get-InventoryData;

        Log 6 "`tStart creating the general.csv file at '$name'."
        if ((-not $config.ignoreMACAddress) -or (-not $config.ignoreSerialNumbers)) {

            $csv_report = @();
            foreach ($sr in $Report) {
                Log 6 "`t`tAdding '$sr' to file."
                $inventorySrv = $inventoryData | Where-Object -Property "Hostname" -Contains -Value ($sr.Hostname);
                ## Create Object with Information
                $csv_report += [ordered]@{
                    Label         = (($inventorySrv | Select-Object -Property "Label").Label)
                    Hostname      = $sr.Hostname
                    Hostname_Mgnt = $sr.Hostname_Mgnt;
                    Serial        = $sr.Serial;
                    MAC_1         = $sr.MAC_1;
                    MAC_2         = $sr.MAC_2;
                    MAC_3         = $sr.MAC_3;
                    MAC_4         = $sr.MAC_4;
                    Mgnt_MAC      = $sr.Mgnt_MAC;
                }

                ## Replace all empty Members with Symbol
                $currentReport = $csv_report[$csv_report.Length - 1];
                foreach ($key in $($currentReport.Keys)) {
                    $currentReport[$key] = $currentReport[$key] | Resolve-NullValuesToSymbol;
                }
                $csv_report[$csv_report.Length - 1] = $currentReport;
            }
            Log 6 "`t`tStart standardizing CSV"
            $csv_report = Get-StandardizedCSV $csv_report;
            $csv_report | ConvertTo-Csv -Delimiter ";" | Out-File -FilePath $name -Force;
        }
    }
}

Function Save-MACInformationToCSV {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomobject]
        $Report
    )
    if ($null -ne $Report) {
        [string]$date = (Get-Date -Format $DATE_FILENAME).ToString();
        $config = Get-Config;
        $name = "$path\ilo_report_$date.csv"
        $path = $config.reportPath;
        $inventoryData = Get-InventoryData;

        $name = "$path\ilo_report_MAC_$date.csv"
        $csv_mac_report = @();
        Log 6 "`tStart creating the macaddress.csv file at '$name'."
        foreach ($sr in $Report) {
            Log 6 "`t`tAdd $sr to file."
            $inventorySrv = $inventoryData | Where-Object -Property "Hostname" -Contains -Value ($sr.Hostname);
            ## Create Object with Information
            $csv_mac = [ordered]@{
                Label         = (($inventorySrv | Select-Object -Property "Label").Label);
                Hostname      = $sr.Hostname;
                Hostname_Mgnt = $sr.Hostname_Mgnt;
                Mgnt_MAC      = $sr.Mgnt_MAC;
            }   

            ## Filter out MAC_Addresses from Report
            Log 6 "`t`t`tAdd NetworkInterfaces to file."
            [int]$i = 1;
            foreach ($nic in $sr.NetworkInterfaces) {
                $nic.MACAddress = $nic.MACAddress;
                $csv_mac.Add(("NetInterf_MAC_$i"), $nic.MACAddress);
                $i++;
            }

            $i = 1
            Log 6 "`t`t`tAdd NetworkAdapters to file."
            foreach ($nad in $sr.NetworkAdapter) {
                foreach ($p in $nad.Ports) {
                    $p.MACAddress = $p.MACAddress;
                    $csv_mac.Add(("NetAdap_MAC_$i"), $p.MACAddress);   
                    $i++; 
                }
            }

            ## Replace all empty Members with Symbol
            foreach ($key in $($csv_mac.Keys)) {
                $csv_mac[$key] = $csv_mac[$key] | Resolve-NullValuesToSymbol;
            }
            $csv_mac_report += $csv_mac
        }
        Log 6 "`t`tStart standardizing CSV"
        $csv_mac_report = Get-StandardizedCSV $csv_mac_report;
        $csv_mac_report | Export-Csv -Path $name -Delimiter ";" -Force;
    }
}

Function Save-SerialInformationToCSV {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $Report
    )
    if ($null -ne $Report) {
        [string]$date = (Get-Date -Format $DATE_FILENAME).ToString();
        $config = Get-Config;
        $name = "$path\ilo_report_$date.csv"
        $path = $config.reportPath;
        $inventoryData = Get-InventoryData;

        $name = "$path\ilo_report_SERIAL_$date.csv"
        Log 6 "`tStart creating the serialnumbers.csv file at '$name'."
        $csv_serial_report = @();
        $csv_additional_info = @();
        foreach ($sr in $Report) {
            Log 6 "`t`tAdd $sr to file."
            $inventorySrv = $inventoryData | Where-Object -Property "Hostname" -Contains -Value ($sr.Hostname);
            ## Create Object with Information
            $csv_serial = [ordered]@{
                Label         = (($inventorySrv | Select-Object -Property "Label").Label);
                Hostname      = $sr.Hostname;
                Hostname_Mgnt = $sr.Hostname_Mgnt;
                Serial        = $sr.Serial;
            }   
            $csv_additional = [ordered]@{
                Label         = (($inventorySrv | Select-Object -Property "Label").Label);
                Hostname      = $sr.Hostname;
                Hostname_Mgnt = $sr.Hostname_Mgnt;
                Serial        = $sr.Serial;
            };

            ## Filter Out Serial Numbers from Report
            Log 6 "`t`t`tAdding Powersupplies to file"
            [int]$i = 1;
            $pwr = $sr.PowerSupply.PowerSupplies;
            foreach ($ps in $pwr) {
                $ps.Serial = $ps.Serial;
                $csv_serial.Add(("PowerSupply$i"), $ps.Serial);
                $csv_additional.Add(("PowerSupply_$i"), $ps.Name);
                $i++;
            }

            Log 6 "`t`t`tAdding Processors to file"
            $i = 1;
            foreach ($pr in $sr.Processor) {
                $pr.Serial = $pr.Serial;
                $csv_serial.Add(("Processor$i"), $pr.Serial);
                $csv_additional.Add(("Processor_$i"), $pr.Model);
                $i++;
            }

            Log 6 "`t`t`tAdding Devices to file"
            $i = 1;
            foreach ($dev in $sr.Devices) {
                if ($iLOVersion -gt 5 -and (-not (($dev -match "supported")))) {
                    $dev.Serial = $dev.Serial;
                    $csv_serial.Add(("Device$i"), $dev.Serial);
                    $csv_additional.Add(("Device_$i"), $dev.Name);
                    $i++;
                }
            }

            Log 6 "`t`t`tAdding Storage to file"
            $i = 1;
            foreach ($stor in $sr.Storage) {
                if ($iLOVersion -lt 6) {
                    $stor.Serial = $stor.Serial;
                    $csv_serial.Add(("Storage$i"), $stor.Serial);
                    $csv_additional.Add(("Storage_$i"), $stor.Name + "," + $stor.Model);
                    $i++;
                }
            }

            Log 6 "`t`t`tAdding Memory to file"
            $i = 1;
            foreach ($mem in $sr.Memory) {
                $mem.Serial = $mem.Serial;
                $csv_serial.Add(("Memory$i"), $mem.Serial)
                $csv_additional.Add(("Memory_$i"), $mem.Location)
                $i++;
            }

            ## Replace all empty Members of Additional with Symbol
            foreach ($key in $($csv_additional.Keys)) {
                $csv_additional[$key] = $csv_additional[$key] | Resolve-NullValuesToSymbol;
            }
            
            ## Replace all empty Members of Serial with Symbol
            foreach ($key in $($csv_serial.Keys)) {
                $csv_serial[$key] = $csv_serial[$key] | Resolve-NullValuesToSymbol;
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

Function Resolve-NullValuesToSymbol {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Value
    )
    if (($null -eq $Value) -or ($Value.Length -le 0)) {
        return $NO_VALUE_FOUND_SYMBOL;
    }
    return $Value;
}