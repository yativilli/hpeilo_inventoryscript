BeforeAll{
    Remove-Module ILO-Inventorizer
    
    Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1 -Force;
    Import-Module HPEiLOCmdlets
}

Describe "General_Functions"{
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

    Context 'Convert-PathsToValidated'{
        Context 'Checking if paths in config are valid and create if not'{
            It 'searchForFilesat'{

            }

            It 'reportPath'{

            }

            It "logPath"{

            }
        }

        Context 'Checking if Paths in config are valid and throw error if not'{
            It 'loginConfigPath'{

            }

            It 'serverPath'{

            }
        }
    }

    Context 'New-File'{
        It 'Path Exists'{

        }

        It 'Path does not exist'{

        }
    }

    Context 'Save-Exception'{
        It "Save Exception"{

        }
    }

    Context "Get-Config"{
        It "has all required fields"{

        }

        It "shows help"{

        }
    }

    Context 'Invoke-ConfigTypeValidation'{
        It 'checks types of config correctly'{

        }
    }

    Context 'Invoke-TypeValidation'{
        It 'checks type correctly'{

        }
    }

    Context 'Log'{
        Context 'File Already exists'{
            It 'saves Logs correctly to file'{

            }

            It 'checks Loglevel'{

            }

            It 'behaves correctly on IgnoreLogActive'
        }

        Context 'File does not exist'{
            It 'creates file if path is specified'{

            }

            It 'writes to console if no config is set'{

            }
        }
    }

    Context 'Invoke-PingTest'{
        It 'should execute an nslookup'{

        }

        It 'should execute a pingtest'{

        }
    }

    Context 'Resolve-NullValuesToSymbol'{
        It 'should resolve value to symbol if null'{

        }
    }

    Context 'Resolve-NullValues'{
        It 'shoud resolve null values to selected symbol'{

        }
    }
}