BeforeAll {
    Remove-Module ILO-Inventorizer
    
    Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1 -Force;
    Import-Module HPEiLOCmdlets

    $configPath = $ENV:TEMP + "\hpeilo_test";
    if ((Test-Path $configPath)) {
        Remove-Item $configPath -Recurse -Force;
    }
    New-Item -ItemType Directory $configPath -Force;
}

Describe "QueryILO_Functions" -Tag "cc" {
    BeforeAll {
        $mockConn = @{ Address = "SomeAddress" };
    }
    BeforeEach {
        InModuleScope ILO-Inventorizer {
            $script:iLOVersion = 4;
        }
    }
    Context "query server" {
        Context "Get-MemoryData" {
            It "should return summary on memory on vs 4" {
                # Arrange
                $mockMemoryData = @{
                    MemoryComponent = @(
                        @{
                            MemoryLocation = "PROC 1 - 1";
                            MemorySizeMB   = 1600;
                        },
                        @{
                            MemoryLocation = "PROC 1 - 2";
                            MemorySizeMB   = 800;
                        }
                    )
                }
                Mock Get-HPEiLOMemoryInfo { $mockMemoryData; } -ModuleName "ILO-Inventorizer";

                # Act 
                $result = $mockConn | Get-MemoryData ;

                # Assert
                for ($i = 0; $i -le $result.Length - 1; $i++) {
                    $result[$i].Location | Should -Be $mockMemoryData.MemoryComponent[$i].MemoryLocation;
                    $result[$i].SizeMB | Should -Be $mockMemoryData.MemoryComponent[$i].MemorySizeMB;
                    $result[$i].Serial | Should -Be "N/A in ILO4";   
                }
                 
            }

            It "should return summary on memory on vs 5" {
                # Arrange
                $mockMemoryData = @{
                    MemoryDetails = @{
                        MemoryData = @(
                            @{
                                DeviceLocator = "PROC 2 - 1";
                                CapacityMiB   = 1600;
                                SerialNumber  = "11992288";
                            },
                            @{
                                DeviceLocator = "PROC 2 - 2";
                                CapacityMiB   = 800;
                                SerialNumber  = "11992288";
                            }
                        )
                    }
                }
                Mock Get-HPEiLOMemoryInfo { $mockMemoryData; } -ModuleName "ILO-Inventorizer";

                # Act
                $result = $mockConn | Get-MemoryData ;

                # Assert
                for ($i = 0; $i -le $result.Length - 1; $i++) {
                    $result[$i].Location | Should -Be $mockMemoryData.MemoryComponent[$i].MemoryLocation;
                    $result[$i].SizeMB | Should -Be $mockMemoryData.MemoryComponent[$i].MemorySizeMB;
                    $result[$i].Serial | Should -Be $mockMemoryData.MemoryComponent[$i].SerialNumber;   
                }
            }
        }
    
        Context "Get-StorageData" {
            It "should return summary on storage on v4 and v5" {
                # Arrange
                $mockStorage = @{
                    Controllers = @{
                        PhysicalDrives = @(
                            @{
                                CapacityGB         = 960
                                InterfaceType      = "SAS"
                                InterfaceSpeedMbps = 12000
                                MediaType          = "SSD"
                                Model              = "HPE MO003840JWFWR"
                                Name               = "PhysicalDrive1"
                                Serial             = "PHYS123456"
                                State              = "OK"
                                SomeOtherProperty  = "ExampleValue"
                                AnotherProperty    = "AnotherExample"
                            },
                            @{
                                CapacityGB         = 940
                                InterfaceType      = "SSAASS"
                                InterfaceSpeedMbps = 10000
                                MediaType          = "HDDD"
                                Model              = "HPE MO003840JWFWR"
                                Name               = "PhysicalDrive2"
                                Serial             = "PHYS0000000"
                                State              = "OK"
                                SomeOtherProperty  = "ExampleValue"
                                AnotherProperty    = "AnotherExample"
                            }      
                        )
                    }
                }
                Mock Get-HPEiLOSmartArrayStorageController { $mockStorage } -ModuleName "ILO-Inventorizer";

                # Act 
                $result = $mockConn | Get-StorageData;

                # Assert
                for ($i = 0; $i -le $result.Length - 1; $i++) {
                    $result[$i].Keys.Count | Should -Be 8;
                }
            }

            it "should return summary above v5" {
                $mockStorage = @{
                    StorageControllers = @(
                        @{
                            CapacityGB         = 960
                            InterfaceType      = "SAS"
                            InterfaceSpeedMbps = 12000
                            MediaType          = "SSD"
                            Model              = "HPE MO003840JWFWR"
                            Name               = "PhysicalDrive1"
                            Serial             = "PHYS123456"
                            State              = "OK"
                            SomeOtherProperty  = "ExampleValue"
                            AnotherProperty    = "AnotherExample"
                        },
                        @{
                            CapacityGB         = 920
                            InterfaceType      = "SFAFS"
                            InterfaceSpeedMbps = 120
                            MediaType          = "NVME M.2 SSD"
                            Model              = "HPE MO003840JWFWR"
                            Name               = "PhysicalDrive2"
                            Serial             = "PHYS123333"
                            State              = "OK"
                            SomeOtherProperty  = "ExampleValue"
                            AnotherProperty    = "AnotherExample"
                        }       
                    )
                }
                Mock Get-HPEiLOStorageController { $mockStorage } -ModuleName "ILO-Inventorizer";
                InModuleScope ILO-Inventorizer {
                    $script:iLOVersion = 6;
                }

                # Act 
                $result = $mockConn | Get-StorageData;

                # Assert
                for ($i = 0; $i -le $result.Length - 1; $i++) {
                    $result[$i].Keys.Count | Should -Be 10;
                }
            }
        }

        Context "Get-DeviceData" {
            It "should return summary on devices" {
                # Arrange
                InModuleScope ILO-Inventorizer {
                    $script:iLOVersion = 6;
                }
                $mockDeviceData = @{
                    DeviceData = @(
                        @{
                            Name       = "Device1"
                            DeviceType = "Type1"
                            Serial     = "123456"
                            Status     = @{
                                State = "OK";
                            }
                            Location   = "Location1"
                        },
                        @{
                            Name         = "Device2"
                            DeviceType   = "Type2"
                            SerialNumber = "654321"
                            Status       = @{
                                State = "Warning";
                            }
                            Location     = "Location2"
                        }
                    )
                } 
                Mock Get-HPEiLODeviceInventory { $mockDeviceData } -ModuleName "ILO-Inventorizer";

                # Act 
                $result = $mockConn | Get-DeviceData;

                # Assert
                for ($i = 0; $i -le $result.Length - 1; $i++) {
                    $result[$i].Name | Should -Be $mockDeviceData.DeviceData[$i].Name;
                    $result[$i].DeviceType | Should -Be $mockDeviceData.DeviceData[$i].DeviceType;
                    $result[$i].Serial | Should -Be $mockDeviceData.DeviceData[$i].SerialNumber;
                    $result[$i].Status | Should -Be $mockDeviceData.DeviceData[$i].Status.State;
                    $result[$i].Location | Should -Be $mockDeviceData.DeviceData[$i].Location;
                }
            }

            It "should return StatusMessage on v4 and v5" {
                # Arrange
                InModuleScope ILO-Inventorizer {
                    $script:iLOVersion = 5;
                }

                $mockStatusMessage = @{
                    StatusInfo = @{
                        Message = "Function not Supported in ILO 4 and 5";
                    }
                }
                Mock Get-HPEiLODeviceInventory { $mockStatusMessage } -ModuleName "ILO-Inventorizer";

                # Act
                $result = $mockConn | Get-DeviceData;

                # Assert
                $result | Should -Be $mockStatusMessage.StatusInfo.Message;
            }
        }

        Context "Format-MACAddressesLikeInventory" {
            It "should format MAC addresses like in inventory" {
                # Arrange
                $mockMAC = @{
                    Name  = "Adapter1"
                    Ports = @(
                        @{ MACAddress = "00:00:00:00:00:00" }
                        @{ MACAddress = "00:00:00:00:00:01" }
                        @{ MACAddress = "AA:AA:AA:AA:AA:01" }
                        @{ MACAddress = "AA:AA:AA:AA:AA:02" }
                        @{ MACAddress = "AA:AA:AA:AA:AA:03" }
                        @{ MACAddress = "AA:AA:AA:AA:AA:04" }
                    )
                }
                Mock Get-NetAdapterData { $mockMAC } -ModuleName "ILO-Inventorizer";

                # Act 
                $result = $mockConn | Format-MACAddressesLikeInventory;

                # Assert
                $result.MAC1 | Should -Be $mockMAC.Ports[2].MACAddress;
                $result.MAC2 | Should -Be $mockMAC.Ports[3].MACAddress;
                $result.MAC3 | Should -Be $mockMAC.Ports[4].MACAddress;
                $result.MAC4 | Should -Be $mockMAC.Ports[5].MACAddress;
            }
        }
    }
}
AfterAll {
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}