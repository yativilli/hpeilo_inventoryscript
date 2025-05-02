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

Describe "ILO-Inventarizer_Functions"{
    Context "Invoke-ParameterSetHandler"{
        It "should should handle 'Config'"{

        }

        It "should should handle 'ServerPath'"{

        }

        It "should should handle 'ServerArray'"{

        }

        It "should should handle 'Inventory'"{

        }

        It "should act to create new config if none is found"{

        }

        It "should do nothing if config is found"{

        }
    }

    Context "Invoke-NoConfigFoundHandler"{
        It "should act to generate empty config if selected"{

        }

        It "should act to generate config with inventory if selected"{

        }

        It "should act to generate config without inventory if selected"{

        }

        It "should act to add path to existing config if selected"{

        }
    }

    Context "Start-PingtestOnServers"{
        It "should read servers from config"{

        }

        It "should ping all servers found and return only the reachable ones"{

        }

        It "should not execute if pingtest is disabled"{

        }
    }
}