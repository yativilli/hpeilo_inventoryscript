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

Describe "End2EndTests"{
    Context "Regular"{
        it "should work without any parameters and without config specified"{

        }

        it "should work with configpath"{

        }

        it "should work with searchstring"{

        }

        it "should work with serverpath"{

        }

        it "should work with serverarray"{

        }
    }

    Context "Scanner"{
        it "should work with scanner"{
            
        }
    }
}

AfterAll{
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}