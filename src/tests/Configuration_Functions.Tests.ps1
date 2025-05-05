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

Describe "Configuration_Functions" {
    BeforeAll {
        $configPath = $ENV:TEMP + "\hpeilo_test";
    }
    BeforeEach {
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
        $login = @{
            Username = "USER"
            Password = "Password"
        };

        $login | ConvertTo-JSON -Depth 2 | Out-File -FilePath ($config.loginConfigPath) -Force;
        $config | ConvertTo-Json -Depth 2 | Out-File -FilePath ($config.configPath) -Force

        # Act
        Set-ConfigPath -Path ($config.configPath);
    }
    Context "Update-Configuration" {
        It "should update the config file" {
            # Arrange
            $configBefore = Get-Content $config.configPath | ConvertFrom-Json -Depth 2;
            $newValueReport = $ENV:APPDATA + "config.tmp";
            $newUsername = "someOtherName";
            $config.reportPath = $newValueReport;
            Mock Test-ForChangesToUpdate { return $config; } -ModuleName "ILO-Inventorizer";
            
            # Act
            Update-Config -ReportPath $newValueReport -Username $newUsername;
            $configAfter = Get-Content $config.configPath | ConvertFrom-Json -Depth 2;
            $loginAfter = Get-Content $config.loginConfigPath | ConvertFrom-Json -Depth 2;

            # Assert
            $configAfter.reportPath | Should -Not -Be $configBefore.reportPath;
            $configAfter.reportPath | Should -Be $newValueReport;
            Should -Invoke -CommandName "Test-ForChangesToUpdate" -ModuleName "ILO-Inventorizer";

            $loginAfter.Username | Should -Not -Be $login.Username;
            $loginAfter.Username | Should -Be $newUsername;
        }

        It "should display help" {
            # Arrange
            Mock Get-Help {} -ParameterFilter { ($Name -eq "Update-Config") } -ModuleName "ILO-Inventorizer";

            # Act
            Update-Config /?
            
            # Assert
            Should -Invoke -CommandName "Get-Help" -Times 1 -ModuleName "ILO-Inventorizer";
        }
    }

    Context "New Config" {
        It "should create an example config without inventory" {
            # Arrange
            $loginPath = $config.loginConfigPath;

            # Act
            New-Config -Path $configPath -NotEmpty -WithOutInventory -LoginPath $loginPath;
            
            # Assert
            $configuration = Get-Config;
            
            $configuration.doNotSearchInventory | Should -Be $true;
            $configuration.serverPath.Length | Should -BeGreaterThan 0;
            (Test-Path $configuration.serverPath) | Should -Be $true;
            $configuration.loginConfigPath | Should -Be $loginPath;
            $configuration.remoteMgmntField | Should -Be "";
            $configuration.searchStringInventory | Should -Be "";
        }

        It "should create an example config with inventory" {
            # Arrange
            $loginPath = $config.loginConfigPath;

            # Act
            New-Config -Path $configPath -NotEmpty -LoginPath $loginPath;

            # Assert
            $configuration = Get-Config;

            $configuration.loginConfigPath | Should -Be $loginPath;
            $configuration.doNotSearchInventory | Should -Be $false;
            $configuration.serverPath.Length | Should -Be 0;
            $configuration.remoteMgmntField.Length | Should -BeGreaterThan 0;
            $configuration.searchStringInventory.Length | Should -BeGreaterThan 0;
        }

        It "should create a config for scanners" {
            # Arrange
            $loginPath = $config.loginConfigPath;

            # Act
            New-Config -Path $configPath -ForScanner -LoginPath $loginPath;
            
            # Assert
            $configuration = Get-Config;

            $configuration.loginConfigPath | Should -Be $loginPath;
            $configuration.doNotSearchInventory | Should -Be $true;
            $configuration.serverPath.Length | Should -Be 0;
            $configuration.remoteMgmntField.Length | Should -Be 0;
            $configuration.searchStringInventory.Length | Should -Be 0;
        }

        It "should create an empty config" {
            # Arrange
            $loginPath = $config.loginConfigPath;

            # Act
            New-Config -Path $configPath -LoginPath $loginPath;

            # Assert 
            $configuration = Get-Config;

            foreach ($key in $configuration.Keys) {
                $isEmpty = $false;
                $login[$key] -eq $null ? ($isEmpty = $true): $false;
                $login[$key] -eq "" ? ($isEmpty = $true): $false;
                $login[$key] -eq 0 ? ($isEmpty = $true): $false;

                $isEmpty | Should -Be $true;
            }
        }
    }

    Context "Save-Config" -Tag "FF" {
        It "should save the config to the specified path" {
            # Arrange
            Set-ConfigPath $config.configPath;
            Remove-Item -Path ($config.configPath) -Force; 
            $doesConfigExistsAtStart = Test-Path $config.configPath;

            # Act
            $config | Save-Config;
            $doesConfigExistAtEnd = Test-Path $config.configPath;
            $configAfter = Get-Config;

            # Assert
            $doesConfigExistsAtStart | Should -Be $false;
            $doesConfigExistAtEnd | Should -Be $true;
            foreach ($key in $configAfter.PSObject.Properties) {
                $isEqual = $key.Value -eq $config[$key.Name];
                $isEqual | Should -Be $true;
            }
        }

        It "should save the login to the specified path" {
            # Arrange Act Assert
            Set-ConfigPath $config.configPath;
            Remove-Item -Path ($config.loginConfigPath) -Force; 
            $doesLoginExistAtStart = Test-Path $config.loginConfigPath;

            # Act
            $config | Save-Config -Login $login
            $doesLoginExistAtEnd = Test-Path $config.loginConfigPath;
            $configAfter = Get-Config;
            $loginAfter = Get-Content ($configAfter.loginConfigPath) | ConvertFrom-Json -Depth 2

            # Assert
            $doesLoginExistAtStart | Should -Be $false;
            $doesLoginExistAtEnd | Should -Be $true;
            foreach ($key in $loginAfter.PSObject.Properties) {
                $isEqual = $key.Value -eq $login[$key.Name];
                $isEqual | Should -Be $true;
            }
        }
    }
}

AfterAll {
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}