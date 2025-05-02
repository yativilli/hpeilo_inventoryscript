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

Describe "Configuration_Functions"{
    Context "Update-Configuration"{
        It "should update the config file"{

        }

        It "should verify the config file contains all necessary information"{

        }

        It "should verify that a configuration exists"{

        }

        It "should display help"{

        }
    }

    Context "New Config"{
        It "should create an example config without inventory"{

        }

        It "should create an example config with inventory"{

        }

        It "should create a config for scanners"{

        }

        It "should create an empty config"{

        }
    }

    Context "Save-Config"{
        It "should save the config to the specified path"{

        }

        It "should save the login to the specified path"{

        }
    }
}

AfterAll{
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}