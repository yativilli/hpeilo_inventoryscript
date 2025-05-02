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

Describe "Server_Scanner"{
    Context "Invoke-ScanServer"{
        It "should ask for serialnumber, hostname and password"{

        }

        It "should resolve errors in order"{

        }

        It "should execute a pingtest before carrying on"{

        }
    }

    Context "Stop-OnExit"{
        It "should stop if input is exit"{

        }
        
        It "should not break if input is not exit"{

        }
    }

    Context "Resolve-ErrorsInInput"{
        It "should filter out prod-id"{

        }

        It "should bring false inputs in correct order"{
            
        }
    }
        
}