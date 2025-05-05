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

Describe "QueryILO_Functions" {
    Context "query server" {
        Context "Get-PowerSupplyData" {
            It "should return summary on power supply" {

            }
        }

        Context "Get-ProcessorData" {
            It "should return summary on processors" {

            }
        }

        Context "Get-MemoryData" {
            It "should return summary on memory" {

            }
        }
    
        Context "Get-StorageData" {
            It "should return summary on storage" {

            }
        }

        Context "Get-NICData" {
            It "should return summary on network" {

            }
        }

        Context "Get-NetAdapterData" {
            It "should return summary on network adapters" {

            }
        }
    
        Context "Get-DeviceData" {
            It "should return summary on devices" {

            }
        }

        Context "Get-IPv4Data" {
            It "should return summary on IPv4" {

            }
        }

        Context "Get-IPv6Data" {
            It "should return summary on IPv6" {

            }
        }

        Context "Get-HealthSummaryData" {
            It "should return summary on health" {

            }
        }

        Context "Format-MACAddressesLikeInventory"{
            It "should format MAC addresses like in inventory"{

            }
        }
    }

    Context "Save in Files"{
        Context "Save-GeneralInformationToCSV"{
            It "should save general information to csv"{

            }

            It "should only be generated if either serials or macs are wanted"{

            }

            It "should resolve-null values"{

            }
        }

        Context "Save-MACInformationToCSV"{
            It "should save mac information to csv"{

            }

            It "should only be generated if macs are wanted"{

            }

            It "should resolve-null values"{

            }
        }

        Context "Save-SerialInformationToCSV"{
            It "should save serial information to csv"{

            }

            It "should only be generated if serials are wanted"{

            }

            It "should resolve-null values"{

            }

            It "should contain information about the things displayed"{
                
            }
        }
    }
}

AfterAll{
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}