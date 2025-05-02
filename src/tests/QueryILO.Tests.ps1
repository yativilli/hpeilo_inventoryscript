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

Describe "QueryILO" {
    Context "Register-Directory" {
        it "should check the path passed in" {

        }

        it "should create new directory if -IgnoreError is set" {

        }

        it "should throw an error if directory is not found" {

        } 

        it "should return directory" {

        }

        it "should return directory even if file is passed" {

        }
    }

    Context "Save Data" {
        Context "Save-DataInJSON" {
            it "should update config with reportpath" {

            }

            it "should save data in file with current date" {

            }
        }

        Context "Save-DataInCSV" {
            it "should update config with reportPath" {
                
            }

            it "should generate generalinformation"{

            }

            it "should generate mac if configured"{

            }

            it "should generate serial if configured"{

            }
        }

        Context "Get-StandardizedCSV"{
            it "should standardize objects so that every has the same keys"{

            }
        }

        Context "Get-InventoryData"{
            it "should return inventory_results"{

            }

            it "should throw error if no file is found"{

            }
        }
    }
}