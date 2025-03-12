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

        Log 0 "Started"
        $report = @();
        foreach ($srv in $servers) {

            $findILO = Find-HPEiLO $srv;
            $iLOVersion = ([regex]"\d").Match($findILO.PN).Value;
            $conn = Connect-HPEiLO -Address $srv -Username $login.Username -Password $login.Password -DisableCertificateAuthentication:($config.deactivateCertificateValidation);

            Log 6 "Querying PowerSupply"
            $powerSupply = ($conn | Get-HPEiLOPowerSupply);
            $powerSuppliesDetails = @();
            foreach ($ps in $powerSupply.PowerSupplies) {
                $powerSuppliesDetails += @{
                    SerialNumber = $ps.SerialNumber;
                    Status       = $iLOVersion -eq 4 ? $ps.Status : $ps.Status.Health;
                    Model        = $ps.Model;
                    Name         = $iLOVersion -eq 4 ? $ps.Label : $ps.Name;
                }
            }
            $powerDetails = @{
                PowerSystemRedundancy = $powerSupply.PowerSupplySummary.PowerSystemRedundancy;
                PresentPowerReading   = $powerSupply.PowerSupplySummary.PresentPowerReading;
                PowerSupplies         = $powerSuppliesDetails;
            }
            
            Log 6 "Querying Processor"
            $processor = ($conn | Get-HPEiLOProcessor).Processor;
            $processorDetails = @();
            foreach ($pr in $processor) {
                $processorDetails += @{
                    Model        = $pr.Model;
                    SerialNumber = $pr.SerialNumber;    
                }
            }

            Log 6 "Querying Memory"
            $memory = $iLOVersion -eq 4 ? ($conn | Get-HPEiLOMemoryInfo).MemoryComponent : ($conn | Get-HPEiLOMemoryInfo).MemoryDetails.MemoryData;
            $memoryDetails = @();
            foreach ($me in $memory) {
                $memoryDetails += @{
                    Location = $iLOVersion -eq 4 ? $me.MemoryLocation.ToString() : $me.DeviceLocator.ToString();
                    SizeMB   = $iLOVersion -eq 4 ? $me.MemorySizeMB.ToString() : $me.CapacityMiB.ToString();
                }
            }            

            Log 6 "Querying NetworkInterfaces"
            $networkInterfaces = ($conn | Get-HPEiLOServerInfo).NICInfo.EthernetInterface;
            $nicDetails = @();
            foreach ($nic in $networkInterfaces) {
                $nicDetails += @{
                    MACAddress    = ([string]$nic.MACAddress).ToLower();
                    Status        = $iLOVersion -eq 4 ? $nic.Status : $nic.Status.State; 
                    InterfaceType = $iLOVersion -eq 4 ? $nic.Location : $nic.InterfaceType;
                }
            }

            Log 6 "Querying NetworkAdapters"
            $networkAdapter = ($conn | Get-HPEiLONICInfo).NetworkAdapter;
            $adapterDetails = @();
            foreach ($na in $networkAdapter) {
                foreach ($neAd in $na.Ports) {
                    $adapterDetails += @{
                        Location   = $na.Location;
                        MACAddress = $neAd.MACAddress;
                        Status     = $iLOVersion -eq 4 ? $na.Status : $na.Status.State;
                    }
                }
            }

            Log 6 "Querying Devices"
            $devices = ($conn | Get-HPEiLODeviceInventory);
            $deviceDetails = @();
            if ($iLOVersion -eq 4) { $deviceDetails = $devices.StatusInfo.Message; }else {
                foreach ($dev in $devices.PCIDevice) {
                    $deviceDetails += @{
                        Name         = $dev.Name;
                        DeviceType   = $dev.DeviceType;
                        Location     = $dev.Location;
                        SerialNumber = $dev.SerialNumber;
                        Status       = $dev.Status.State;
                    }
                }
            }

            Log 6 "Querying Storage"
            $storage; 
            $storageDetails = @();
            if (($iLOVersion -eq 4) -or ($iLOVersion -eq 5)) { 
                ($storage = Get-HPEiLOSmartArrayStorageController).Controllers; 
                <#
                foreach ($st in $storage) {
                    $storageDetails += @{
                        
                }
                #>
                $storageDetails = $storage;
            }
            else {
                $storage = ($conn | Get-HPEiLOStorageController).StorageControllers;
                <#
            foreach ($st in $storage) {
                $storageDetails += @{
                    
            }
            #>
                $storageDetails = $storage;
            }
    
            Log 6 "Querying IPv4-Configuration"
            $ipv4 = ($conn | Get-HPEiLOIPv4NetworkSetting);
            $ipv4Details = @{
                IPv4Address       = $ipv4.IPv4Address;
                IPv4SubnetMask    = $ipv4.IPv4SubnetMask;
                IPv4Gateway       = $ipv4.IPv4Gateway;
                IPv4AddressOrigin = $ipv4.IPv4AddressOrigin;
                MACAddress        = $ipv4.MACAddress;
                DNSServer         = $ipv4.DNSServer;
                FQDN              = $ipv4.FQDN;
                DomainName        = $ipv4.DomainName;
            };


            Log 6 "Querying IPv6-Configuration"
            $ipv6 = ($conn | Get-HPEiLOIPv6NetworkSetting);
            $ipv6Details = @{
                IPv6Address       = $ipv6.IPv6Address.Value.ToLower();
                DNSServer         = $ipv6.DNSServer;
                MACAddress        = $ipv6.MACAddress.ToLower();
                PreferredProtocol = $ipv4.PreferredProtocol;
            };

            Log 6 "Querying Health-Summary"
            $healthSummary = ($conn | Get-HPEiLOHealthSummary);
            $healthDetails = @{
                FanStatus           = $healthSummary.FanStatus;
                MemoryStatus        = $healthSummary.MemoryStatus;
                PowerSuppliesStatus = $healthSummary.PowerSuppliesStatus;
                ProcessorStatus     = $healthSummary.ProcessorStatus;
                StorageStatus       = $healthSummary.StorageStatus;
                TemperatureStatus   = $healthSummary.TemperatureStatus;
            }


            Log 0 "$srv querried"

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
        $report | ConvertTo-Json -Depth 10 | Out-File "U:\IPA\IPA\hpeilo_inventoryscript\r.json";
    }
    catch {
        Write-Error $_;
    }
}