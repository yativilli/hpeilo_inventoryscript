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

Describe "QueryInventory"{
    Context "Invoke-InventoryResponseCleaner"{
        It "should transform it from a weird array to an object"{

        }

        It "should only carry on with SRV*-Servers"{

        }

        It "should only carry on with servers that have a mgnt_hostname"{

        }
    }

    Context "Save-ServersFromInventory"{
        It "should create servers.json if not exists"{

        }

        It "should add to server.json if exists"{

        }

        It "should throw error if no server path is configured."{
            
        }
    }
}
AfterAll{
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}