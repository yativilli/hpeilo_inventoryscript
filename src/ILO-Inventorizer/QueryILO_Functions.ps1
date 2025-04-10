. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Functions.ps1

Function Get-PowerSupplyData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
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
        return $powerDetails;
    }
}

Function Get-ProcessorData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
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
        return $processorDetails;
    }
}

Function Get-MemoryData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
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
        return $memoryDetails;
    }
}

Function Get-NICData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
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
        return $nicDetails;
    }
}

Function Get-NetAdapterData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
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
        return $adapterDetails;
    }
}

Function Get-DeviceData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
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
        return $deviceDetails;
    }
}

Function Get-StorageData {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
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
        return $storageDetails;
    }
}

Function Get-IPv4Data {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
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
        return $ipv4Details;
    }
}

Function Get-IPv6Data {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
        # Query IPv6 Configuration
        Log 6 "`tQuerying IPv6-Configuration" -IgnoreLogActive
        $ipv6 = ($conn | Get-HPEiLOIPv6NetworkSetting);
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
        $conn
    )
    if ($null -ne $conn) {
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
        return $healthDetails
    }
}

Function Format-MACAddressesLikeInventory {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $conn
    )
    if ($null -ne $conn) {
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