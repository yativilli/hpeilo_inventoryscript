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
        BeforeAll{
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

        BeforeEach{
            if(Test-Path ($config.serverPath)){
                Remove-Item $config.serverPath -Force
            }
        }

        It "should should handle 'Config'"{
            $ENV:HPEILOCONFIG = "";
            Invoke-ParameterSetHandler -ParameterSetName 'Config' -ConfigPath ($config.configPath)
            (Get-ConfigPath) | Should -Be $config.configPath;
        }

        It "should should handle 'ServerPath'" {
            $ENV:HPEILOCONFIG = "";
            $srv = @("srv1", "srv2", "srv3");
            $srv | ConvertTo-JSON -Depth 2 | Out-File -FilePath ($config.serverPath);
            Invoke-ParameterSetHandler -ParameterSetname 'ServerPath' -ConfigPath ($config.configPath) -LoginPath ($config.loginConfigPath);
            $configuration = Get-Config;

            ($configuration.configPath) | Should -Be ($GeneratedPathConfig);
            ($configuration.loginConfigPath) | Should -Be ($config.loginConfigPath);
            "$(Get-Content ($configuration.serverPath) -Force)" | Should -Match ("$(ConvertTo-JSON $srv)");
            ($configuration.doNotSearchInventory) | Should -Be $true
        }

        It "should should handle 'ServerArray'" {
            $ENV:HPEILOCONFIG = "";
            Invoke-ParameterSetHandler -ParameterSetName 'ServerArray' -ConfigPath ($config.configPath) -LoginPath ($config.loginConfigPath);
            $configuration = Get-Config;
            ($configuration.configPath) | Should -Be ($GeneratedPathConfig);
            ($configuration.loginConfigPath) | Should -Be ($config.loginConfigPath);
            ($configuration.doNotSearchInventory) | Should -Be $true
        }

        It "should should handle 'Inventory'" {
            $ENV:HPEILOCONFIG = "";
            Invoke-ParameterSetHandler -ParameterSetName 'Inventory' -LoginPath ($config.loginConfigPath);
            $configuration = Get-Config;
            ($configuration.doNotSearchInventory) | Should -Be $false;
            ($configuration.searchStringInventory) | Should -Be "rmgfa-sioc-cs";
            ($configuration.remoteMgmntField) | Should -Be "Hostname Mgnt"
        }

        It "should act to create new config if none is found" {
            $ENV:HPEILOCONFIG = "";
            Mock Invoke-NoConfigFoundHandler { return } -ModuleName "ILO-Inventorizer";
            Invoke-ParameterSetHandler -ParameterSetName 'None';

            Should -Invoke -CommandName "Invoke-NoConfigFoundHandler" -Times 1 -ModuleName "ILO-Inventorizer";
        }

        It "should do nothing if config is found" {
            Mock Invoke-NoConfigFoundHandler {return} -ModuleName "ILO-Inventorizer";
            Mock New-Config {return} -ModuleName "ILO-Inventorizer";
            Mock Update-Config {return} -ModuleName "ILO-Inventorizer";
            Mock Set-ConfigPath {return} -ModuleName "ILO-Inventorizer"; 
            
            $Env:HPEILOCONFIG = $config.configPath;
            Invoke-ParameterSetHandler -ParameterSetName "None";
            Should -Invoke -CommandName "Invoke-NoConfigFoundHandler" -Times 0 -ModuleName "ILO-Inventorizer";
            Should -Invoke -CommandName "New-Config" -Times 0 -ModuleName "ILO-Inventorizer";
            Should -Invoke -CommandName "Update-Config" -Times 0 -ModuleName "ILO-Inventorizer";
            Should -Invoke -CommandName "Set-ConfigPath" -Times 0 -ModuleName "ILO-Inventorizer";
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

AfterAll{
    # Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}