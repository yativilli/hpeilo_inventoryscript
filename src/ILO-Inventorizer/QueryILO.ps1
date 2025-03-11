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
       
            $healthSummary = ($conn | Get-HPEiLOHealthSummary);
           
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
            
            $processor = ($conn | Get-HPEiLOProcessor).Processor;
            $processorDetails = @();
            foreach ($pr in $processor) {
                $processorDetails += @{
                    Model        = $pr.Model;
                    SerialNumber = $pr.SerialNumber;    
                }
            }

            $memory = $iLOVersion -eq 4 ? ($conn | Get-HPEiLOMemoryInfo).MemoryComponent : ($conn | Get-HPEiLOMemoryInfo).MemoryDetails.MemoryData;
            $memoryDetails = @();
            foreach ($me in $memory) {
                $memoryDetails += @{
                    Location = $iLOVersion -eq 4 ? $me.MemoryLocation.ToString() : $me.DeviceLocator.ToString();
                    SizeMB   = $iLOVersion -eq 4 ? $me.MemorySizeMB.ToString() : $me.CapacityMiB.ToString();
                }
            }            

            Log 0 "$srv querried"

            $srvReport = [ordered]@{
                Serial         = $findILO.SerialNumber;
                Part_Type_Name = $conn.TargetInfo.ProductName;
                Hostname       = ($conn | Get-HPEiLOAccessSetting).ServerName.ToLower();
                Hostname_Mgnt  = $conn.Hostname.ToLower();
                MAC_1          = "";
                MAC_2          = "";
                MAC_3          = "";
                MAC_4          = "";
                Mgnt_MAC       = ($conn | Get-HPEiLOIPv4NetworkSetting).PermanentMACAddress.ToLower();

                Health_Summary = @{
                    FanStatus           = $healthSummary.FanStatus;
                    MemoryStatus        = $healthSummary.MemoryStatus;
                    PowerSuppliesStatus = $healthSummary.PowerSuppliesStatus;
                    ProcessorStatus     = $healthSummary.ProcessorStatus;
                    StorageStatus       = $healthSummary.StorageStatus;
                    TemperatureStatus   = $healthSummary.TemperatureStatus;
                }

                PowerSupply    = @{
                    PowerSystemRedundancy = $powerSupply.PowerSupplySummary.PowerSystemRedundancy;
                    PresentPowerReading   = $powerSupply.PowerSupplySummary.PresentPowerReading;
                    PowerSupplies         = $powerSuppliesDetails;
                }
                
                Processor      = $processorDetails
                
                Memory         = $memoryDetails
                Network        = ""
                NetworkAdapter = ""
                PCIDevices     = ""
                USBDevices     = ""
                Devices        = ""
                Storage        = ""
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