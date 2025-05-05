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

Describe "ILO-Inventorizer" {
    BeforeAll {
        $configPath = $ENV:TEMP + "\hpeilo_test";
    }
    Context "Set-ConfigPath" {
        it "should provide help if prompted" {
            # Arrange
            Mock Get-Help {} -ParameterFilter { ($Name -eq "Set-ConfigPath") } -ModuleName "ILO-Inventorizer";

            # Act
            Set-ConfigPath -h
            
            # Assert
            Should -Invoke -CommandName "Get-Help" -Times 1 -ModuleName "ILO-Inventorizer";
        }

        it "should reset path on switch" {
            # Arrange
            $pathAtBeginning = "C:\Users\Default";
            $ENV:HPEILOCONFIG = $pathAtBeginning;

            # Act
            Set-ConfigPath -Reset;

            # Assert
            $pathAtEnd = $ENV:HPEILOCONFIG;
            $pathAtBeginning | Should -Not -Be $pathAtEnd;
            $pathAtEnd | Should -Be "";
        }

        it "should set path" {
            # Arrange
            $ENV:HPEILOCONFIG = "";
            if (Test-Path $configPath) {
                Remove-Item $configPath -Force -Confirm:$false;
            }
            New-Item -ItemType Directory $configPath -Force;
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
            $pathToSet = $config.configPath;

            # Act
            Set-ConfigPath -Path $pathToSet;

            # Assert
            $pathAtEnd = $ENV:HPEILOCONFIG;
            $pathAtEnd | Should -Be $pathToSet
            $pathAtEnd | Should -Not -Be "";
        }

        it "should check provided path for a file"  -Tag "CC" {
            # Arrange
            $ENV:HPEILOCONFIG = "";
            $pathToSet = $ENV:TEMP + "\somePathThatShouldNotExist\Folder";
            if (Test-Path $pathToSet) {
                Remove-Item $pathToSet -Force;
            }
            Mock Save-Exception {} -ParameterFilter { $_.Exception.Message.ToString() -match "The path '.*' does not exist." } -ModuleName "ILO-Inventorizer"

            # Act
            Set-ConfigPath -Path $pathToSet;


            # Assert
            Should -Invoke -CommandName "Save-Exception" -ModuleName "ILO-Inventorizer" -Times 1;
            ($ENV:HPEILOCONFIG) | Should -Be "";
        }

        it "should provide path to file if exists in directory but is not linked" {
            # Arrange
            $ENV:HPEILOCONFIG = "";
            $pathToSet = $configPath;

            if (Test-Path $configPath) {
                Remove-Item $configPath -Force -Confirm:$false -Recurse;
            }
            New-Item -ItemType Directory $configPath -Force;
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

            # Act
            Set-ConfigPath -Path $pathToSet;

            # Assert
            $pathToSet | Should -Not -Match "(\.tmp)|(\.json)"
            ($ENV:HPEILOCONFIG) | Should -Be ($config.configPath);
        }

        it "should throw error if path does not contain any usable file" {
            # Arrange
            $ENV:HPEILOCONFIG = "";
            $pathToSet = $configPath + "\noUsableFilesInside";
 
            if (Test-Path $pathToSet) {
                Remove-Item -Path $pathToSet -Recurse -Force;
            }
            New-Item -ItemType Directory $pathToSet -Force;

            Mock Save-Exception {} -ParameterFilter { $_.Exception.Message.ToString() -match "The Path '.*' must include a 'config.json' or 'config.tmp'" } -ModuleName "ILO-Inventorizer"

            # Act
            Set-ConfigPath -Path $pathToSet;

            # Assert
            ($ENV:HPEILOCONFIG) | Should -Be "";
            Should -Invoke -CommandName "Save-Exception" -ModuleName "ILO-Inventorizer" -Times 1
        }
    }

    Context "Get-ConfigPath" {
        it "should provide help if prompted" {
            # Arrange
            Mock Get-Help {} -ParameterFilter { ($Name -eq "Get-ConfigPath") } -ModuleName "ILO-Inventorizer";

            # Act
            Get-ConfigPath /?
            
            # Assert
            Should -Invoke -CommandName "Get-Help" -Times 1 -ModuleName "ILO-Inventorizer";
        }

        it "should return path to config" {
            # Arrange
            $expectedPathToConfig = $ENV:TEMP + "\config.tmp"
            $ENV:HPEILOCONFIG = $expectedPathToConfig;

            # Act 
            $actualPathToConfig = Get-ConfigPath;

            # Assert
            $expectedPathToConfig | Should -Be $actualPathToConfig;
        }

        it "should return an error if no config is set" {
            # Arrange
            $ENV:HPEILOCONFIG = "";
            Mock Save-Exception {} -ParameterFilter { $_.Exception.Message.ToString() -match "No configuration has been set: Please use 'Set-ConfigPath', 'Get-NewConfig' or 'Get-HWInfoFromILO' to generate a new config" } -ModuleName "ILO-Inventorizer"

            # Act
            Get-ConfigPath;

            # Assert
            Should -Invoke -CommandName "Save-Exception" -Times 1 -ModuleName "ILO-Inventorizer"
        }
    }

    Context "Get-NewConfig" {
        it "should reset config path" {
            # Arrange
            $pathAtBeginning = $ENV:TEMP + "\config.tmp"
            $ENV:HPEILOCONFIG = $pathAtBeginning;
            Mock Get-HWInfoFromILO { } -ModuleName "ILO-Inventorizer";
            
            # Act
            Get-NewConfig;
            
            # Assert
            $isEmpty = $ENV:HPEILOCONFIG.Length -eq 0
            $isEmpty | Should -Be $true;
            Should -Invoke -CommandName "Get-HWInfoFromILO" -ModuleName "ILO-Inventorizer" -Times 1;
        }
    }
}

AfterAll {
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}