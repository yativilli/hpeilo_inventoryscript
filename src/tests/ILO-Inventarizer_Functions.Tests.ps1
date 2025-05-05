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

Describe "ILO-Inventarizer_Functions" {
    Context "Invoke-ParameterSetHandler" {
        BeforeAll {
            $configPath = $ENV:TEMP + "\hpeilo_test";
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
            
            $login = @{
                Username = "USER"
                Password = "Password"
            }

            $login | ConvertTo-JSON -Depth 2 | Out-File -FilePath ($config.loginConfigPath) -Force;
            $config | ConvertTo-JSON -Depth 2 | Out-File -FilePath ($config.configPath) -Force;

            $GeneratedPathConfig = $ENV:TEMP + "\hpeilo" + "\hpeilo_config.tmp"
        }

        BeforeEach {
            if (Test-Path ($config.serverPath)) {
                Remove-Item $config.serverPath -Force
            }
        }

        It "should should handle 'Config'" {
            # Arrange
            $ENV:HPEILOCONFIG = "";
            # Act
            Invoke-ParameterSetHandler -ParameterSetName 'Config' -ConfigPath ($config.configPath)
            # Assert
            (Get-ConfigPath) | Should -Be $config.configPath;
        }

        It "should should handle 'ServerPath'" {
            # Arrange
            $ENV:HPEILOCONFIG = "";
            $srv = @("srv1", "srv2", "srv3");
            $srv | ConvertTo-JSON -Depth 2 | Out-File -FilePath ($config.serverPath);

            # Act
            Invoke-ParameterSetHandler -ParameterSetname 'ServerPath' -ConfigPath ($config.configPath) -LoginPath ($config.loginConfigPath);
            $configuration = Get-Config;

            # Assert
            ($configuration.configPath) | Should -Be ($GeneratedPathConfig);
            ($configuration.loginConfigPath) | Should -Be ($config.loginConfigPath);
            "$(Get-Content ($configuration.serverPath) -Force)" | Should -Match ("$(ConvertTo-JSON $srv)");
            ($configuration.doNotSearchInventory) | Should -Be $true
        }

        It "should should handle 'ServerArray'" {
            # Arrange
            $ENV:HPEILOCONFIG = "";

            # Act
            Invoke-ParameterSetHandler -ParameterSetName 'ServerArray' -ConfigPath ($config.configPath) -LoginPath ($config.loginConfigPath);
            $configuration = Get-Config;

            # Assert
            ($configuration.configPath) | Should -Be ($GeneratedPathConfig);
            ($configuration.loginConfigPath) | Should -Be ($config.loginConfigPath);
            ($configuration.doNotSearchInventory) | Should -Be $true
        }

        It "should should handle 'Inventory'" {
            # Arrange
            $ENV:HPEILOCONFIG = "";

            # Act
            Invoke-ParameterSetHandler -ParameterSetName 'Inventory' -LoginPath ($config.loginConfigPath);
            $configuration = Get-Config;

            # Assert
            ($configuration.doNotSearchInventory) | Should -Be $false;
            ($configuration.searchStringInventory) | Should -Be "rmgfa-sioc-cs";
            ($configuration.remoteMgmntField) | Should -Be "Hostname Mgnt"
        }

        It "should act to create new config if none is found" {
            # Arrange
            $ENV:HPEILOCONFIG = "";
            Mock Invoke-NoConfigFoundHandler { return } -ModuleName "ILO-Inventorizer";
            
            # Act
            Invoke-ParameterSetHandler -ParameterSetName 'None';

            # Assert
            Should -Invoke -CommandName "Invoke-NoConfigFoundHandler" -Times 1 -ModuleName "ILO-Inventorizer";
        }

        It "should do nothing if config is found" {
            # Arrange
            Mock Invoke-NoConfigFoundHandler { return } -ModuleName "ILO-Inventorizer";
            Mock New-Config { return } -ModuleName "ILO-Inventorizer";
            Mock Update-Config { return } -ModuleName "ILO-Inventorizer";
            Mock Set-ConfigPath { return } -ModuleName "ILO-Inventorizer"; 
            $Env:HPEILOCONFIG = $config.configPath;
            
            # Act
            Invoke-ParameterSetHandler -ParameterSetName "None";
            
            # Assert
            Should -Invoke -CommandName "Invoke-NoConfigFoundHandler" -Times 0 -ModuleName "ILO-Inventorizer";
            Should -Invoke -CommandName "New-Config" -Times 0 -ModuleName "ILO-Inventorizer";
            Should -Invoke -CommandName "Update-Config" -Times 0 -ModuleName "ILO-Inventorizer";
            Should -Invoke -CommandName "Set-ConfigPath" -Times 0 -ModuleName "ILO-Inventorizer";
        }
    }

    Context "Invoke-NoConfigFoundHandler" {
        BeforeAll {
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
            
            $login = @{
                Username = "USER"
                Password = "Password"
            }
            
            Set-ConfigPath $config.configPath;
            $login | ConvertTo-JSON -Depth 2 | Out-File -FilePath ($config.loginConfigPath) -Force;
            $config | ConvertTo-JSON -Depth 2 | Out-File -FilePath ($config.configPath) -Force;
        }
        It "should act to generate empty config if selected" {
            # Arrange
            $configDecision = 1;
            Mock Read-Host { return $configDecision; } -ParameterFilter { ($Prompt -join '').Contains("Enter the corresponding number:") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return $configPath; } -ParameterFilter { ($Prompt -join '').Contains("Where do you want to save the config at?") } -ModuleName "ILO-Inventorizer";
            Mock Add-EmptyConfig {} -ModuleName "ILO-Inventorizer"

            # Act
            Invoke-NoConfigFoundHandler;
            
            # Assert
            Should -Invoke -CommandName "Add-EmptyConfig" -Times 1 -ModuleName "ILO-Inventorizer";
        }

        It "should act to generate config with inventory if selected" {
            # Arrange
            $configDecision = 2;
            $withInventory = "y";
            Mock Read-Host { return $configDecision; } -ParameterFilter { ($Prompt -join '').Contains("Enter the corresponding number:") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return $configPath; } -ParameterFilter { ($Prompt -join '').Contains("Where do you want to save the config at?") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return $withInventory; } -ParameterFilter { ($Prompt -join '').Contains("Do you want to:`nRead From Inventory [y/N]?") } -ModuleName "ILO-Inventorizer";
            Mock Add-ExampleConfigWithInventory {} -ModuleName "ILO-Inventorizer";

            # Act
            Invoke-NoConfigFoundHandler;
            
            # Assert
            Should -Invoke -CommandName "Add-ExampleConfigWithInventory" -Times 1 -ModuleName "ILO-Inventorizer";
        }

        It "should act to generate config without inventory if selected" {
            # Arrange
            $configDecision = 2;
            $withInventory = "N";
            Mock Read-Host { return $configDecision; } -ParameterFilter { ($Prompt -join '').Contains("Enter the corresponding number:") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return $configPath; } -ParameterFilter { ($Prompt -join '').Contains("Where do you want to save the config at?") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return $withInventory; } -ParameterFilter { ($Prompt -join '').Contains("Do you want to:`nRead From Inventory [y/N]?") } -ModuleName "ILO-Inventorizer";
            Mock Add-ExampleConfigWithoutInventory {} -ModuleName "ILO-Inventorizer";

            # Act 
            Invoke-NoConfigFoundHandler;

            # Assert 
            Should -Invoke -CommandName "Add-ExampleConfigWithoutInventory" -Times 1 -ModuleName "ILO-Inventorizer";
        }

        It "should act to add path to existing config if selected" {
            # Arrange
            $configDecision = 3;
            Mock Read-Host { return $configDecision; } -ParameterFilter { ($Prompt -join '').Contains("Enter the corresponding number:") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return $configPath; } -ParameterFilter { ($Prompt -join '').Contains("Where do you have the config stored at?") } -ModuleName "ILO-Inventorizer";
            Mock Set-ConfigPath {} -ModuleName "ILO-Inventorizer";

            # Act
            Invoke-NoConfigFoundHandler

            # Assert
            Should -Invoke -CommandName "Set-ConfigPath" -Times 1 -ModuleName "ILO-Inventorizer"
        }
    }

    Context "Start-PingtestOnServers" {
        BeforeEach {
            # Arrange
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
            
            $login = @{
                Username = "USER"
                Password = "Password"
            }

            $srv = @(
                "srv001",
                "srv002",
                "srv003",
                "srv004"
            )
            
            Set-ConfigPath $config.configPath;
            $login | ConvertTo-JSON -Depth 2 | Out-File -FilePath ($config.loginConfigPath) -Force;
            $config | ConvertTo-JSON -Depth 2 | Out-File -FilePath ($config.configPath) -Force;
            $srv | ConvertTo-Json -Depth 2 | Out-File -FilePath ($config.serverPath) -Force;
        }

        It "should read all servers from config and return only the reachable ones" {
            # Arrange
            $expectedReachable = 2;
            $expectedUnreachable = 2;
            Mock Invoke-PingTest { return $true; } -ParameterFilter { ($Hostname -eq $srv[0]) -or ($Hostname -eq $srv[2]) } -ModuleName "ILO-Inventorizer"
            Mock Invoke-PingTest { return $false; } -ParameterFilter { ($Hostname -eq $srv[1]) -or ($Hostname -eq $srv[3]) } -ModuleName "ILO-Inventorizer"
            Mock Get-Config { return $config; } -ModuleName "ILO-Inventorizer"
            
            # Act
            $res = Start-PingtestOnServers;
            
            # Assert
            ($res.Count) | Should -Be $expectedReachable;
            ($srv.Count - $res.Count) | Should -Be $expectedUnreachable;
            $res[0] | Should -Be $srv[0];
            $res[1] | Should -Be $srv[2];
            $srv.Count | Should -Not -Be $res.Count;
        }

        It "should not execute if pingtest is disabled" {
            # Arrange
            $config.deactivatePingtest = $true;
            Mock Get-Config { return $config; } -ModuleName "ILO-Inventorizer"
            Mock Invoke-PingTest {} -ModuleName "ILO-Inventorizer";

            # Act
            $res = Start-PingtestOnServers;

            # Assert
            Should -Invoke -CommandName "Invoke-PingTest" -Times 0 -ModuleName "ILO-Inventorizer";
            $srv.Count | Should -Be $res.Count;
        }
    }
}

AfterAll {
    # Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}