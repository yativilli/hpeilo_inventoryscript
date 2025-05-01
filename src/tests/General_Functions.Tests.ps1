BeforeAll {
    Remove-Module ILO-Inventorizer
    
    Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1 -Force;
    Import-Module HPEiLOCmdlets
}

Describe "General_Functions" {
    Context 'Show-Help' {
        Context "Checking if the user requires" {

            It 'on /?' {
                (Show-Help "/?") | Should -Be $true
            }

            It 'on --help' {
            (Show-Help "--help") | Should -Be $true
            }

            It 'on -h' {
            (Show-Help "-h") | Should -Be $true
            }
        
            It 'on other strings' {
            (Show-Help "help") | Should -Be $false
            }
        }
    }

    Context 'Convert-PathsToValidated' {
        BeforeEach {
            $configPath = $ENV:TEMP + "\hpeilo_test";
            New-Item -ItemType Directory -Path $configPath -Force;
            $config = [ordered]@{
                searchForFilesAt                = $configPath + "\Scanner\s"
                configPath                      = $configPath + "\config.tmp"
                loginConfigPath                 = $configPath + "\login.tmp"
                reportPath                      = $configPath + "\Scanner\g"
                serverPath                      = $configPath + "\Scanner\srv\srv.tmp"
                logPath                         = $configPath + "\Scanner\log"
                logLevel                        = 0
                loggingActivated                = $false
                searchStringInventory           = ""
                doNotSearchInventory            = $false
                remoteMgmntField                = ""
                deactivateCertificateValidation = $false
                deactivatePingtest              = $false
                logToConsole                    = $false
                ignoreMACAddress                = $false
                ignoreSerialNumbers             = $false
            }; 

            $login = @(
                @{
                    Username = "SomeUser"
                    Password = "SomePassword"
                }
            )

            $config | ConvertTo-Json -Depth 2 | Out-File -FilePath ($config.configPath) -Force
            $login | ConvertTo-Json -Depth 2 | Out-File -FilePath ($config.loginConfigPath) -Force
            Set-ConfigPath -Path $config.configPath;
        }

        Context 'Checking if paths in config are valid and create if not' {
            It 'searchForFilesat' {
                $configuration = Get-Config;
                if (Test-Path ($configuration.searchForFilesAt)) {
                    Remove-Item -Path ($configuration.searchForFilesAt) -Force
                }
                Convert-PathsToValidated -IgnoreServerPath;
                Test-Path ($configuration.searchForFilesAt) | Should -Be $true
            }

            It 'reportPath' {
                $configuration = Get-Config;
                if (Test-Path ($configuration.reportPath)) {
                    Remove-Item -Path ($configuration.reportPath) -Force
                }
                Convert-PathsToValidated -IgnoreServerPath;
                Test-Path ($configuration.reportPath) | Should -Be $true
            }

            It "logPath" {
                $configuration = Get-Config;
                if (Test-Path ($configuration.logPath)) {
                    Remove-Item -Path ($configuration.logPath) -Force
                }
                Convert-PathsToValidated -IgnoreServerPath;
                Test-Path ($configuration.logPath) | Should -Be $true
            }
        }

        Context 'Checking if Paths in config are valid and throw error if not' {
            It 'loginConfigPath' {
                $configuration = Get-Config;
                Remove-Item($configuration.loginConfigPath) -Force; 
                try {
                    Convert-PathsToValidated -ErrorAction Stop  
                }
                catch {
                    $exceptionMessage = $_.Exception.Message
                    $exceptionMessage | Should -Be "Path to '$($config.loginConfigPath)' could not be resolved. Verify that loginConfigPath includes some file like 'login.json' and it and the file must exist for the script to work. It also must include a Username and a Password."
                }
            }

            It 'serverPath' {
                $configuration = Get-Config;
                if (Test-Path ($configuration.serverPath)) {
                    Remove-Item -Path ($configuration.serverPath) -Force
                }
                try {
                    Convert-PathsToValidated -ErrorAction Stop    
                }
                catch {
                    $exceptionMessage = $_.Exception.Message
                    $exceptionMessage | Should -Be "Path to '$($config.loginConfigPath)' could not be resolved. Verify that serverPath includes some file like 'server.json' and it and the file must exist for the script to work, with it containing an array of servers."
                }
            }
        }
    }


    Context 'New-File' {
        BeforeAll{
            $path = $ENV:TEMP + "\temporary\stuff";
            Remove-Item $path -Force
        }
        It 'Path does not exist' {
            $path = $ENV:TEMP + "\temporary\stuff";
            $pathExists = Test-Path $path;

            New-File $path;
            $pathNowExists = Test-Path $path;
            
            $pathExists | Should -Be $false;
            $pathNowExists | Should -Be $true;
        }
        It 'Path Exists' {
            $path = $ENV:TEMP + "\temporary\stuff";
            $pathExists = Test-Path $path;

            New-File $path;
            $pathNowExists = Test-Path $path;
            
            $pathExists | Should -Be $true;
            $pathNowExists | Should -Be $true;
        }
    }

    Context 'Save-Exception' -Tag "FF" -Skip{
        BeforeAll{
            $configuration_exc = @{
                logPath = $ENV:TEMP + "\hpeilo_test"
                logLevel = 0
                loggingActivated = $false
                logToConsole = $false
            }

            ($configuration_exc | ConvertTo-Json) | Out-File -Path ($configuration_exc.logPath) -Force;
            Set-ConfigPath = $configuration_exc.logPath;
        }

        It "Save Exception" {
            $err = [System.Management.Automation.RuntimeException] "Throw some error."
            $path = "$((Get-Config).logPath)\$(Get-Date -Format "yyyy_MM_dd").txt"
            Write-Host $path;
            Save-Exception $err "Throw error";
            $logContent = Get-Content $path -Force;
            $logContent;

        }
    }

    Context "Get-Config" {
        It "has all required fields" {

        }

        It "shows help" {

        }
    }

    Context 'Invoke-ConfigTypeValidation' {
        It 'checks types of config correctly' {

        }
    }

    Context 'Invoke-TypeValidation' {
        It 'checks type correctly' {

        }
    }

    Context 'Log' {
        Context 'File Already exists' {
            It 'saves Logs correctly to file' {

            }

            It 'checks Loglevel' {

            }

            It 'behaves correctly on IgnoreLogActive' {

            }
        }

        Context 'File does not exist' {
            It 'creates file if path is specified' {

            }

            It 'writes to console if no config is set' {

            }
        }
    }

    Context 'Invoke-PingTest' {
        It 'should execute an nslookup' {

        }

        It 'should execute a pingtest' {

        }
    }

    Context 'Resolve-NullValuesToSymbol' {
        It 'should resolve value to symbol if null' {

        }
    }

    Context 'Resolve-NullValues' {
        It 'shoud resolve null values to selected symbol' {

        }
    }
}