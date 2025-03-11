. .\ILO-Inventorizer\Constants.ps1
. .\ILO-Inventorizer\Functions.ps1

Function Get-DataFromILO {
    param(
        [Parameter()]
        [Array]
        $servers
    )
    Write-Host $servers;
    Get-Module HPEiLOCmdlets;

    $config = Get-Config;
    $login = Get-Content -Path $config.loginConfigPath | ConvertFrom-Json -Depth 2;

    $report = @();
    foreach ($srv in $servers) {

        $findILO = Find-HPEiLO $srv;
        $conn = Connect-HPEiLO -Address $srv -Username $login.Username -Password $login.Password -DisableCertificateAuthentication:($config.deactivateCertificateValidation);
       
        $healthSummary = ($conn | Get-HPEiLOHealthSummary);
        $powerSupply = ($conn | Get-HPEiLOPowerSupply);

        $srvReport = [ordered]@{
            Serial         = $findILO.SerialNumber;
            Part_Type_Name = $conn.TargetInfo.ProductName;
            Hostname       = ($conn | Get-HPEiLOAccessSetting).ServerName.ToLower();
            Hostname_Mgnt  = $conn.Hostname.ToLower();
            MAC_1          = $conn;
            MAC_2          = $conn;
            MAC_3          = $conn;
            MAC_4          = $conn;
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
                PresentPowerReading = $powerSupply.PowerSupplySummary.PresentPowerReading;
                PowerSupplies = @(
                    foreach($s in $powerSupply.PowerSupplies){
                        return $s.Status;
                    }
                )
            }
            Memory         = ""
            Processor      = ""
            Network        = ""
            NetworkAdapter = ""
            PCIDevices     = ""
            USBDevices     = ""
            Devices        = ""
            Storage        = ""
        }

        $report += $srvReport;
    }

    $report
}