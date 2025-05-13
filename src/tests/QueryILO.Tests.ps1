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
    BeforeEach {
        $config = [ordered]@{
            searchForFilesAt                = $configPath
            configPath                      = $configPath + "\config.tmp"
            loginConfigPath                 = $configPath + "\login.tmp"
            reportPath                      = $configPath
            serverPath                      = $configPath + "\srv.tmp"
            logPath                         = $configPath
            logLevel                        = 2
            loggingActivated                = $true
            searchStringInventory           = ""
            doNotSearchInventory            = $false
            remoteMgmntField                = ""
            deactivateCertificateValidation = $false
            deactivatePingtest              = $false
            logToConsole                    = $false
            ignoreMACAddress                = $false
            ignoreSerialNumbers             = $false
        }; 
        $config | ConvertTo-Json -Depth 2 | Out-File -FilePath ($config.configPath) -Force
        $ENV:HPEILOCONFIG = $config.configPath;
    }
    
    Context "Register-Directory" {
        it "should check the path passed in and throw error if the path does not exist" {
            # Arrange
            Set-ConfigPath -Path $config.configPath;
            $pathToCheck = $config.searchForFilesAt + "\frenchfries";
            Mock Test-Path { return $false; } -ModuleName "ILO-Inventorizer";
            Mock Save-Exception {} -ParameterFilter { $_ -match "The directory at '.*' does not exist. Please verify that the specified path and all its parent folders exist." } -ModuleName "ILO-Inventorizer";
            
            # Act
            Register-Directory -Path $pathToCheck;

            # Assert
            Should -Invoke -CommandName "Test-Path" -ModuleName "ILO-Inventorizer";
            Should -Invoke -CommandName "Save-Exception" -ModuleName "ILO-Inventorizer";   
        }

        it "should create new directory if -IgnoreError is set and return path" {
            # Arrange
            Set-ConfigPath -Path $config.configPath;
            $pathToCheck = $config.searchForFilesAt + "\frenchfries";
            $doesExistBefore = Test-Path $pathToCheck;
            Mock Save-Exception {} -ModuleName "ILO-Inventorizer";

            # Act
            $res = Register-Directory -Path $pathToCheck -IgnoreError;
            $doesExistAfter = Test-Path $pathToCheck;

            # Assert
            $res | Should -Be $pathToCheck;
            $doesExistBefore | Should -Be $false;
            $doesExistAfter | Should -Be $true;
            Should -Invoke "Save-Exception" -Times 0 -ModuleName "ILO-Inventorizer";

            Remove-Item $pathToCheck -Force -Recurse;
        }

        it "should return directory when already exists" {
            # Arrange
            Set-ConfigPath -Path $config.configPath;
            $pathToCheck = $config.searchForFilesAt + "\frenchfries";
            New-Item -ItemType Directory $pathToCheck -Force;

            # Act
            $res = Register-Directory -Path $pathToCheck;

            # Assert
            $res | Should -Be $pathToCheck;
        }

        it "should return directory even if file is in the path" {
            # Arrange
            Set-ConfigPath -Path $config.configPath;
            $pathExpected = $config.searchForFilesAt + "\frenchfries";
            $pathToCheck = $pathExpected + "\burger.json";
            New-Item -ItemType File $pathToCheck -Force;

            # Act
            $res = Register-Directory -Path $pathToCheck;

            # Assert
            $res | Should -Be $pathExpected;
            $res | Should -Not -Be $pathToCheck;
        }
    }

    Context "Save Data" {
        Context "Save-DataInJSON" {
            it "should update config with reportpath if it contains wrong path" {
                # Arrange
                $repPath = $config.reportPath;
                Set-ConfigPath -Path $config.configPath;
                $report = @{ Something = "Something Else" }
                $reportPathWithFile = $repPath + "\abc.json";
                New-Item $reportPathWithFile -Force;
                Update-Config -ReportPath $reportPathWithFile;

                [string]$date = (Get-Date -Format "yyyy_MM_dd").ToString();
                $name = "$($config.reportPath)\ilo_report_$date.json";
                # Act
                $res = Save-DataInJSON -Report $report;

                # Assert
                (Test-Path $name) | Should -Be $true;   
                $res | Should -Be $name;
                $conf = Get-Config;
                $conf.reportPath | Should -Be $repPath;
                
                $resJSON = Get-Content -Path $res -Force | ConvertFrom-Json -Depth 2;
                foreach ($key in $resJSON.PSObject.Properties.Name) {
                    $resJSON.$key | Should -Be $report[$key];
                }

                Remove-Item $name -Force;
            }
        }

        Context "Save-DataInCSV" {
            AfterEach {
                $configPath = $ENV:TEMP + "\hpeilo_test";
                Get-ChildItem $configPath | Where-Object { $_.Name -match ".csv" } | Remove-Item -Force
            }
            it "should update config with reportPath" {
                # Arrange
                $repPath = $config.reportPath;
                Set-ConfigPath -Path $config.configPath;
                $report = Get-Content (Resolve-Path ".\tests\ilo_report_example.json") | ConvertFrom-Json;
                $reportPathWithFile = $repPath + "\abc.json";
                New-Item $reportPathWithFile -Force;
                Update-Config -ReportPath $reportPathWithFile -IgnoreMACAddress:$true -IgnoreSerialNumbers:$true;
                Mock Save-GeneralInformationToCSV { } -ModuleName "ILO-Inventorizer";

                # Act
                $res = Save-DataInCSV -Report $report;

                # Assert
                
                $res | Should -Be $repPath;
                Should -Invoke "Save-GeneralInformationToCSV" -Times 1 -ModuleName "ILO-Inventorizer";
            }

            it "should generate general info" {
                # Arrange
                $repPath = $config.reportPath;
                Set-ConfigPath -Path $config.configPath;
                Copy-Item -Path "$PSScriptRoot\inventory_results.json" -Destination ($config.searchForFilesAt + "\inventory_results.json") -Force;
                $report = Get-Content (Resolve-Path "$PSScriptRoot\ilo_report_example.json") | ConvertFrom-Json -Depth 10;
                Update-Config -IgnoreMACAddress:$true;

                # Act
                Save-DataInCSV $report;
               
                # Assert
                $childrenGen = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(MAC){0}[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenMAC = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(MAC){1}_[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenGen | Should -Be 1;
                $childrenMAC | Should -Be 0;
            }

            it "should generate mac if configured" {
                # Arrange
                $repPath = $config.reportPath;
                Set-ConfigPath -Path $config.configPath;
                Copy-Item -Path "$PSScriptRoot\inventory_results.json" -Destination ($config.searchForFilesAt + "\inventory_results.json") -Force;
                $report = Get-Content (Resolve-Path "$PSScriptRoot\ilo_report_example.json") | ConvertFrom-Json -Depth 10;
                Update-Config -IgnoreSerialNumbers:$true;

                # Act
                Save-DataInCSV $report;
               
                # Assert
                $childrenGen = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(MAC){0}[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenSerial = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(SERIAL){1}_[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count 
                $childrenMAC = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(MAC){1}_[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenGen | Should -Be 1;
                $childrenSerial | Should -Be 0;
                $childrenMAC | Should -Be 1;
            }

            it "should generate serial if configured" {
                # Arrange
                $repPath = $config.reportPath;
                Set-ConfigPath -Path $config.configPath;
                Copy-Item -Path "$PSScriptRoot\inventory_results.json" -Destination ($config.searchForFilesAt + "\inventory_results.json") -Force;
                $report = Get-Content (Resolve-Path "$PSScriptRoot\ilo_report_example.json") | ConvertFrom-Json -Depth 10;
                Update-Config -IgnoreMACAddress:$true;

                # Act
                Save-DataInCSV $report;
               
                # Assert
                $childrenGen = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(MAC){0}[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenMAC = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(MAC){1}_[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenSerial = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(SERIAL){1}_[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenGen | Should -Be 1;
                $childrenMAC | Should -Be 0;
                $childrenSerial | Should -Be 1;
            }

            it "should generate no csv if neither serial or mac is true" {
                # Arrange
                $repPath = $config.reportPath;
                Set-ConfigPath -Path $config.configPath;
                Copy-Item -Path "$PSScriptRoot\inventory_results.json" -Destination ($config.searchForFilesAt + "\inventory_results.json") -Force;
                $report = Get-Content (Resolve-Path "$PSScriptRoot\ilo_report_example.json") | ConvertFrom-Json -Depth 10;
                Update-Config -IgnoreMACAddress:$true -IgnoreSerialNumbers:$true;

                # Act
                Save-DataInCSV $report;
               
                # Assert
                $childrenGen = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(MAC){0}[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenMAC = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(MAC){1}_[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenSerial = (Get-ChildItem $repPath | Where-Object { $_.Name -match "ilo_report_(SERIAL){1}_[0-9]{4}_[0-9]{2}_[0-9]{2}\.csv" }).Count
                $childrenGen | Should -Be 0;
                $childrenMAC | Should -Be 0;
                $childrenSerial | Should -Be 0;
            }
        }

        Context "Get-StandardizedCSV" {
            it "should standardize objects so that every has the same keys" {
                # Arrange
                $objectToCsv = @(
                    [ordered]@{
                        Name     = "France"
                        Location = "Europe"
                        Republic = $true;
                    },
                    [ordered]@{
                        Name       = "Germany"
                        Population = 80000000
                        President  = "Frank-Walter Steinmeier"
                    }
                )
                
                # Act
                $resp = (Get-StandardizedCSV $objectToCsv);
                
                # Assert
                $objectToFR_MemberCount = $objectToCsv[0].Keys.Count;
                $respFR_MemberCount = $resp[0].Keys.Count;
                $respFR_MemberCount | Should -Be $objectToFR_MemberCount;
                
                $objectToDE_MemberCount = $objectToCsv[1].Keys.Count;
                $respDE_MemberCount = $resp[1].Keys.Count;
                $respDE_MemberCount | Should -Be $objectToDE_MemberCount;

                $objectToFR_MemberCount | Should -Be $objectToDE_MemberCount;
                
            }
        }

        Context "Get-InventoryData" {
            BeforeEach {
                Set-ConfigPath -Path $config.configPath;
                $invPath = $config.searchForFilesAt + "\inventory_results.json"
                Copy-Item -Path "$PSScriptRoot\inventory_results.json" -Destination $invPath -Force;
            }
            it "should return inventory_results" {
                # Arrange
                $inventoryExpResult = Get-Content $invPath | ConvertFrom-Json -Depth 2;

                # Act
                $inventoryRes = Get-InventoryData;

                # Assert
                "$inventoryRes" | Should -Be "$inventoryExpResult";
            }

            it "should throw error if no file is found" {
                # Arrange
                Remove-Item $invPath -Force -Recurse;

                # Act & Assert
                { Get-InventoryData -ErrorAction Stop } | Should -Throw "The file '$invPath' does not exist or has been moved. Do not move or delete, as it is vital to query from Inventory." 
            }
        }
    }
}

AfterAll {
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}