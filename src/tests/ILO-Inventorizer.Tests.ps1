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

Describe "ILO-Inventorizer"{
    Context "Set-ConfigPath"{
        it "should provide help if prompted"{

        }

        it "should reset path on switch"{

        }

        it "should set path"{

        }

        it "should check provided path for a file"{

        }

        it "should provide path to file if exists in directory but is not linked"{

        }

        it "should throw error if path does not contain any usable file"{

        }
    }

    Context "Get-ConfigPath"{
        it "should provide help if prompted"{

        }

        it "should return path to config"{

        }

        it "should return an error if no config is set"{

        }
    }

    Context "Get-NewConfig"{
        it "should reset config path"{

        }

        it "should call Get-InfoFromILO to start process over"{
            
        }
    }
}