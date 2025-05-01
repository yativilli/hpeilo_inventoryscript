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
        BeforeAll {
            $path = $ENV:TEMP + "\temporary\stuff";
            if ((Test-Path $path)) {
                Remove-Item $path -Force
            }
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
        AfterAll {
            Remove-Item -Path ($ENV:TEMP + "\temporary\stuff");
        }
    }

    Context 'Save-Exception' {
        BeforeAll {
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
            $err = [System.Management.Automation.RuntimeException] "Throw some error."
            $path = "$((Get-Config).logPath)\$(Get-Date -Format "yyyy_MM_dd").txt"
            Save-Exception $err "Throw Error to test" -ErrorAction SilentlyContinue;
            [string]$logContent = (Get-Content $path -Force)
            $logContent | Should -Match ".*Throw Error to test";
        }
    }

    Context "Get-Config" {
        BeforeAll {
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
            $configuration = Get-Config;
            $countGet = ([array]$configuration.PSObject.Properties).Count;
            $countActual = $config.Count;

            (ConvertTo-Json $config) | Should -Be (ConvertTo-Json $configuration);
            
            # Verify all Properties are displayed
            ([pscustomobject]$countGet) | Should -Be $countActual;
            
        }

        It "shows help" {
            $help = ( Get-Config /? )
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
                $config | Invoke-ConfigTypeValidation
            }
            catch {
                [string]($_.Exception.Message) | Should -Match ".*Your configuration has wrong types: 'logLevel' must be of type 'long' but is instead of type 'string'"
            } 
        }
    }

    Context 'Invoke-TypeValidation' {
        It 'throws error if type is not correct' {
            [type]$expectedType = [string];
            $name = "TestAttribute";

            $inputValue = 1234.56;
            [type]$inputType = $inputValue.GetType();

            $result = "";
            try {
                Invoke-TypeValidation -Value $inputValue -ExpectedType $expectedType -Name $name;
            }
            catch {
                $result = $_.Exception.Message;
            } 
            $result | Should -Match ".*Your configuration has wrong types: '$name' must be of type '$expectedType' but is instead of type '$inputType'"
        }
        
        It 'throws no error if type is correct' {
            $expectedType = [string];
            $name = "TestAttribute";
            $inputValue = "123456";
        
            $result = "";
            try {
                Invoke-TypeValidation -Value $inputValue -ExpectedType $expectedType -Name $name;
            }
            catch {
                $result = $_.Exception.Message;
            } 
            Write-Host $result;
            $result.Length | Should -BeLessOrEqual 0;
        }
    }

    Context 'Log' -Tag "FF" {
        BeforeAll{
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

            $currentDay = (Get-Date -Format "yyyy_MM_dd")+".txt";
        }
        Context 'File Already exists' {
            It 'saves Logs correctly to file' {
                Log 1 "Test";
                $path = $config.logPath + "\$currentDay";
                $logContent = Get-Content -Path $path -Force;

                [regex]$expectedLog = "[0-9]{4}\.[0-9]{2}\.[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\	Test"
                $logContent | Should -Match $expectedLog;
            }

            It 'checks Loglevel' {
                $expectedLog = "[0-9]{4}\.[0-9]{2}\.[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\	"
                $path = $config.logPath + "\$currentDay";
                # Above
                Log 3 "Test above";
                $expectedAboveLog = $expectedLog + "Test above";
                # Below
                Log 1 "Test below";
                $expectedBelowLog = $expectedLog + "Test below";
                # Exactly   
                Log 2 "Test exactly";
                $expectedExactlyLog = $expectedLog + "Test exactly";

                $logContent = "$(Get-Content -Path $path -Force)";
                $logContent | Should -Not -Match $expectedAboveLog;
                $logContent | Should -Match $expectedExactlyLog;
                $logContent | Should -Match $expectedBelowLog;

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

    Context "Resolve-NullValues" {
        BeforeAll {
            $NO_VALUE_FOUND_SYMBOL = Get-NoValueFoundSymbol;
        }
        Context 'Resolve-NullValuesToSymbol' {
            It 'should resolve value to symbol if null' {
                $testString = $null;
                $testString = Resolve-NullValuesToSymbol -Value $testString;
                $testString | Should -Be $NO_VALUE_FOUND_SYMBOL
            }
            It 'should not resolve value to symbol if not null' {
                $testString = "Hamburger";
                $expectedString = $testString;

                $testString = Resolve-NullValuesToSymbol -Value $testString;
                $testString | Should -Not -Be $NO_VALUE_FOUND_SYMBOL;
                $testString | Should -Be $expectedString;
            }
        }
    
        Context 'Resolve-NullValues' {
            It 'shoud resolve null values to selected symbol' {
                $testString = $null;
                $resolveToSymbol = "%%";

                $testString = Resolve-NullValues -Value $testString -ValueOnNull $resolveToSymbol;
                $testString | Should -Be $resolveToSymbol;
            }
            It 'should not resolve value to symbol if not null' {
                $testString = "French Fries";
                $expectedString = $testString;
                $resolveToSymbol = "%%";

                $testString = Resolve-NullValues -Value $testString -ValueOnNull $resolveToSymbol;
                $testString | Should -Not -Be $resolveToSymbol;
                $testString | Should -Be $expectedString;
            }
        }
    }
}