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
            # Arrange
            $configPath = $ENV:TEMP + "\hpeilo_test";
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
                # Arrange
                $configuration = Get-Config;
                if (Test-Path ($configuration.searchForFilesAt)) {
                    Remove-Item -Path ($configuration.searchForFilesAt) -Force
                }

                # Act
                Convert-PathsToValidated -IgnoreServerPath;
                
                # Assert
                Test-Path ($configuration.searchForFilesAt) | Should -Be $true
            }

            It 'reportPath' {
                # Arrange
                $configuration = Get-Config;
                if (Test-Path ($configuration.reportPath)) {
                    Remove-Item -Path ($configuration.reportPath) -Force
                }

                # Act
                Convert-PathsToValidated -IgnoreServerPath;
                
                # Assert
                Test-Path ($configuration.reportPath) | Should -Be $true
            }

            It "logPath" {
                # Arrange
                $configuration = Get-Config;
                if (Test-Path ($configuration.logPath)) {
                    Remove-Item -Path ($configuration.logPath) -Force
                }

                # Act
                Convert-PathsToValidated -IgnoreServerPath;
                
                # Assert
                Test-Path ($configuration.logPath) | Should -Be $true
            }
        }

        Context 'Checking if Paths in config are valid and throw error if not' {
            It 'loginConfigPath' {
                # Arrange
                $configuration = Get-Config;
                Remove-Item($configuration.loginConfigPath) -Force; 
                try {
                    # Act
                    Convert-PathsToValidated -ErrorAction Stop  
                }
                catch {
                    # Assert
                    $exceptionMessage = $_.Exception.Message
                    $exceptionMessage | Should -Be "Path to '$($config.loginConfigPath)' could not be resolved. Verify that loginConfigPath includes some file like 'login.json' and it and the file must exist for the script to work. It also must include a Username and a Password."
                }
            }

            It 'serverPath' {
                # Arrange
                $configuration = Get-Config;
                if (Test-Path ($configuration.serverPath)) {
                    Remove-Item -Path ($configuration.serverPath) -Force
                }
                try {
                    # Act
                    Convert-PathsToValidated -ErrorAction Stop    
                }
                catch {
                    # Assert
                    $exceptionMessage = $_.Exception.Message
                    $exceptionMessage | Should -Be "Path to '$($config.loginConfigPath)' could not be resolved. Verify that serverPath includes some file like 'server.json' and it and the file must exist for the script to work, with it containing an array of servers."
                }
            }
        }
    }


    Context 'New-File' {
        BeforeAll {
            # Arrange
            $path = $ENV:TEMP + "\temporary\stuff";
            if ((Test-Path $path)) {
                Remove-Item $path -Force
            }
        }
        It 'Path does not exist' {
            # Arrange
            $path = $ENV:TEMP + "\temporary\stuff";
            $pathExists = Test-Path $path;

            # Act
            New-File $path;
            
            # Assert
            $pathNowExists = Test-Path $path;
            
            $pathExists | Should -Be $false;
            $pathNowExists | Should -Be $true;
        }
        It 'Path Exists' {
            # Arrange
            $path = $ENV:TEMP + "\temporary\stuff";
            $pathExists = Test-Path $path;
                
            # Act
            New-File $path;
            $pathNowExists = Test-Path $path;
            
            # Assert
            $pathExists | Should -Be $true;
            $pathNowExists | Should -Be $true;
        }
        AfterAll {
            Remove-Item -Path ($ENV:TEMP + "\temporary\stuff");
        }
    }

    Context 'Save-Exception' {
        BeforeAll {
            # Arrange
            $configuration_exc = @{
                logPath          = $ENV:TEMP + "\hpeilo_test"
                logLevel         = 1
                loggingActivated = $true
                logToConsole     = $false
            }

            ($configuration_exc | ConvertTo-Json) | Set-Content -Path ($configuration_exc.logPath + "\config.tmp") -Force;
            $path = "$((Get-Config).logPath)\$(Get-Date -Format "yyyy_MM_dd").txt"
            if (Test-Path $path) {
                Remove-Item $path -Force;
            }
            Set-ConfigPath $configuration_exc.logPath;
        }

        It "Save Exception" {
            # Arrange
            $err = [System.Management.Automation.RuntimeException] "Throw some error."
            $path = "$((Get-Config).logPath)\$(Get-Date -Format "yyyy_MM_dd").txt"
            
            # Act
            Save-Exception $err "Throw Error to test" -ErrorAction SilentlyContinue;
            
            # Assert
            [string]$logContent = (Get-Content $path -Force)
            $logContent | Should -Match ".*Throw Error to test";
        }
    }

    Context "Get-Config" {
        BeforeAll {
            # Arrange
            $configPath = $ENV:TEMP + "\hpeilo_test";
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
            $config | ConvertTo-Json -Depth 2 | Out-File -FilePath ($config.configPath) -Force
            Set-ConfigPath -Path $config.configPath;
        }
        It "returns object with all properties" {
            # Act
            $configuration = Get-Config;
            $countGet = ([array]$configuration.PSObject.Properties).Count;
            $countActual = $config.Count;

            (ConvertTo-Json $config) | Should -Be (ConvertTo-Json $configuration);
            
            # Assert/ Verify all Properties are displayed
            ([pscustomobject]$countGet) | Should -Be $countActual;
            
        }

        It "shows help" {
            # Act
            $help = ( Get-Config /? )
            
            # Assert
            $functDescr = ($help.details.description.Text);
            $functName = $help.details.Name;
            
            $actualHelp = Get-Help Get-Config -Full; 
            $actualFunctDescr = $actualHelp.details.description.Text;
            $actialFunctName = $actualHelp.details.Name;

            $functDescr | Should -Be $actualFunctDescr;
            $functName | Should -Be $actialFunctName;
        }
    }

    Context 'Invoke-ConfigTypeValidation' {
        BeforeAll {
            # Arrange
            $configPath = $ENV:TEMP + "\hpeilo_test";
            $config = [ordered]@{
                searchForFilesAt                = $configPath + "\Scanner\s"
                configPath                      = $configPath + "\config.tmp"
                loginConfigPath                 = $configPath + "\login.tmp"
                reportPath                      = $configPath + "\Scanner\g"
                serverPath                      = $configPath + "\Scanner\srv\srv.tmp"
                logPath                         = $configPath + "\Scanner\log"
                logLevel                        = "Error"
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
        }
        It 'throws error if type is not correct' {
            try {
                # Act
                $config | Invoke-ConfigTypeValidation
            }
            catch {
                # Assert
                [string]($_.Exception.Message) | Should -Match ".*Your configuration has wrong types: 'logLevel' must be of type 'long' but is instead of type 'string'"
            } 
        }
    }

    Context 'Invoke-TypeValidation' {
        It 'throws error if type is not correct' {
            # Arrange
            [type]$expectedType = [string];
            $name = "TestAttribute";

            $inputValue = 1234.56;
            [type]$inputType = $inputValue.GetType();

            $result = "";
            try {
                # Act
                Invoke-TypeValidation -Value $inputValue -ExpectedType $expectedType -Name $name;
            }
            catch {
                $result = $_.Exception.Message;
            } 
            # Assert
            $result | Should -Match ".*Your configuration has wrong types: '$name' must be of type '$expectedType' but is instead of type '$inputType'"
        }
        
        It 'throws no error if type is correct' {
            # Arrange
            $expectedType = [string];
            $name = "TestAttribute";
            $inputValue = "123456";
        
            $result = "";
            try {
                # Act
                Invoke-TypeValidation -Value $inputValue -ExpectedType $expectedType -Name $name;
            }
            catch {
                $result = $_.Exception.Message;
            } 
            # Assert
            $result.Length | Should -BeLessOrEqual 0;
        }
    }

    Context 'Log' {
        BeforeAll {
            # Arrange
            $configPath = $ENV:TEMP + "\hpeilo_test";
            $config = [ordered]@{
                searchForFilesAt                = $configPath + "\Scanner\s"
                configPath                      = $configPath + "\config.tmp"
                loginConfigPath                 = $configPath + "\login.tmp"
                reportPath                      = $configPath + "\Scanner\g"
                serverPath                      = $configPath + "\Scanner\srv\srv.tmp"
                logPath                         = $configPath + "\Scanner\log"
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
            Set-ConfigPath -Path $config.configPath;

            $currentDay = (Get-Date -Format "yyyy_MM_dd") + ".txt";
            $path = $config.logPath + "\$currentDay";
        }
        Context 'File Already exists' {
            It 'saves Logs correctly to file' {
                # Act
                Log 1 "Test";
                
                # Assert
                $logContent = Get-Content -Path $path -Force;
                [regex]$expLog = "[0-9]{4}\.[0-9]{2}\.[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\	Test"
                $logContent | Should -Match $expLog;
            }

            It 'checks Loglevel' {
                # Act
                #########
                # Above
                Log ($config.logLevel + 1) "Test above";
                [regex]$expectedAboveLog = "[0-9]{4}\.[0-9]{2}\.[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\	Test above";
                # Below
                Log ($config.logLevel - 1) "Test below";
                [regex]$expectedBelowLog = "[0-9]{4}\.[0-9]{2}\.[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\	Test below";
                # Exactly   
                Log ($config.logLevel) "Test exactly";
                [regex]$expectedExactlyLog = "[0-9]{4}\.[0-9]{2}\.[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\	Test exactly";

                # Assert
                $logContent = "$(Get-Content -Path $path -Force)";
                $logContent | Should -Not -Match $expectedAboveLog;
                $logContent | Should -Match $expectedExactlyLog;
                $logContent | Should -Match $expectedBelowLog;
            }

            It 'behaves correctly on IgnoreLogActive' {
                # Arrange
                $pathToConsoleOutput = Start-Transcript -Path ($config.logPath + "\consoleOutput.txt") -Force;
                
                # Act
                Log 4 "Test IgnoreLogActive" -IgnoreLogActive;
                Stop-Transcript

                # Assert
                $pathToConsoleOutput = $pathToConsoleOutput.Split("is ")[1];
                $consoleOutput = "$(Get-Content $pathToConsoleOutput -Force)";
                $consoleOutput | Should -Match "[0-9]{4}\.[0-9]{2}\.[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\	Test IgnoreLogActive";

                $logContent = "$(Get-Content -Path $path -Force)";
                $logContent | Should -Match "[0-9]{4}\.[0-9]{2}\.[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\	Test IgnoreLogActive";
            }
        }

        Context 'File does not exist' {
            It 'creates file if path is specified' {
                # Arrange
                if (Test-Path $path) {
                    Remove-Item -Path $path -Force;
                }

                # Act
                Log 1 "Test if file is created";

                # Assert
                Test-Path $path | Should -Be $true;
                $logContent = "$(Get-Content -Path $path -Force)";
                [regex]$expLog = "[0-9]{4}\.[0-9]{2}\.[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\	Test if file is created"
                $logContent | Should -Match $expLog;

            }

            It 'writes to console if no config is set' {
                # Arrange
                Set-ConfigPath -Reset;
                $ENV:HPEILO_LogWarning = $null;
                $pathToConsoleOutput = Start-Transcript -Path ($config.logPath + "\consoleOutput.txt") -Force;

                # Act
                Log 1 "Test log to console if no config is set";
                
                Start-Sleep -Seconds 0.5
                Stop-Transcript
                
                # Assert
                $pathToConsoleOutput = $pathToConsoleOutput.Split("is ")[1];
                $consoleOutput = "$(Get-Content $pathToConsoleOutput -Force)";
                [regex]$expLog = "LOG: Test log to console if no config is set"
                $consoleOutput | Should -Match $expLog;
            }
        }
    }

    Context 'Invoke-PingTest' {
        BeforeAll {
            # Arrange
            $configPath = $ENV:TEMP + "\hpeilo_test";
            $config = [ordered]@{
                searchForFilesAt                = $configPath + "\Scanner\s"
                configPath                      = $configPath + "\config.tmp"
                loginConfigPath                 = $configPath + "\login.tmp"
                reportPath                      = $configPath + "\Scanner\g"
                serverPath                      = $configPath + "\Scanner\srv\srv.tmp"
                logPath                         = $configPath + "\Scanner\log"
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
            Set-ConfigPath -Path $config.configPath;

            Mock Resolve-DnsName { return @{Name = "www.google.com"; IPAddress = "127.0.0.1" } } -ParameterFilter { $Hostname -eq "www.google.com" } -ModuleName "ILO-Inventorizer";
            Mock Test-Connection { return $true } -ParameterFilter { $Hostname -eq "www.google.com" } -ModuleName "ILO-Inventorizer";
        }
        
        It 'should execute an nslookup' {
            # Arrange
            $hostname = "www.google.com";

            # Act
            $pingtest = Invoke-PingTest $hostname
            
            # Assert
            Should -Invoke -CommandName "Resolve-DnsName" -Times 1 -ModuleName "ILO-Inventorizer";
            $pingtest | Should -Be $true
        }
        It 'should execute a pingtest' {
            # Arrange
            $hostname = "www.google.com";
            
            # Act
            $pingtest = Invoke-PingTest $hostname
            
            # Assert
            Should -Invoke -CommandName "Test-Connection" -Times 1 -ModuleName "ILO-Inventorizer";
            $pingtest | Should -Be $true
        }
    }

    Context "Resolve-NullValues" {
        BeforeAll {
            $NO_VALUE_FOUND_SYMBOL = "-";
        }
        Context 'Resolve-NullValuesToSymbol' {
            It 'should resolve value to symbol if null' {
                # Arrange
                $testString = $null;
                
                # Act
                $testString = Resolve-NullValuesToSymbol -Value $testString;
                
                # Assert
                $testString | Should -Be $NO_VALUE_FOUND_SYMBOL
            }
            It 'should not resolve value to symbol if not null' {
                # Arrange
                $testString = "Hamburger";
                $expectedString = $testString;

                # Act
                $testString = Resolve-NullValuesToSymbol -Value $testString;
                
                # Assert
                $testString | Should -Not -Be $NO_VALUE_FOUND_SYMBOL;
                $testString | Should -Be $expectedString;
            }
        }
    
        Context 'Resolve-NullValues' {
            It 'shoud resolve null values to selected symbol' {
                # Arrange
                $testString = $null;
                $resolveToSymbol = "%%";

                # Act
                $testString = Resolve-NullValues -Value $testString -ValueOnNull $resolveToSymbol;
                
                # Assert
                $testString | Should -Be $resolveToSymbol;
            }
            It 'should not resolve value to symbol if not null' {
                # Arrange
                $testString = "French Fries";
                $expectedString = $testString;
                $resolveToSymbol = "%%";

                # Act
                $testString = Resolve-NullValues -Value $testString -ValueOnNull $resolveToSymbol;
                
                # Assert
                $testString | Should -Not -Be $resolveToSymbol;
                $testString | Should -Be $expectedString;
            }
        }
    }
}

AfterAll {
    # Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}