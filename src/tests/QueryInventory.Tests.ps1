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

Describe "QueryInventory" {
    BeforeEach {
        $config = [ordered]@{
            searchForFilesAt                = $configPath
            configPath                      = $configPath + "\config.tmp"
            loginConfigPath                 = $configPath + "\login.tmp"
            reportPath                      = $configPath
            serverPath                      = "";
            logPath                         = $configPath
            logLevel                        = 2
            loggingActivated                = $true
            searchStringInventory           = ""
            doNotSearchInventory            = $false
            remoteMgmntField                = "Hostname Mgnt"
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
        Set-ConfigPath -Path $config.configPath;
    }
    Context "Invoke-InventoryResponseCleaner" {
        BeforeEach {
            $inventoryAnswer = '{
                "d": {
                    "__type": "IV4.Backend.DTOs.Search.SearchResult",
                    "Columns": ["Label", "Hostname", "Hostname Mgnt", "Serial", "Part Type", "Facility", "MAC 1", "MAC 2", "MAC 3", "MAC 4", "Mgnt MAC", "HW Status", "OS" ],      
                    "Rows": [["ILO0106", "Zeus", null, null, "ILO Module Int", "-", "00:00:00:00:00:01", null, null, null, null, "Tested", null            ],
                    ["ILO0108", "Hera", null, null, "ILO Module Int", "-", "00:00:00:00:00:02", null, null, null, null, "Tested", null ],
                    ["SRV0067", "Athena", "Athena-Mgmt", "CZ12345", "ProLiant DL380p Gen8", "-", "00:00:00:00:00:03", "00:00:00:00:00:04", "00:00:00:00:00:05", "00:00:00:00:00:06", "00:00:00:00:00:07", "Tested", "Windows Server 2016"],               
                    ["SRV0224", "Apollo", "Apollo-Mgmt", "CZ12346", "ProLiant DL380 Gen11", null, null, null, null, null, null, "Tested", null ]
                    ]
                }
            }';
    
        }
        It "should transform it from a weird array to an object" {
            # Arrange
            $response = $inventoryAnswer | ConvertFrom-Json -Depth 5;
            $correctCount = 2; # Athena and Apollo in this case
            $hostname1 = "Athena-Mgmt"
            $hostname2 = "Apollo-Mgmt"
            
            # Act
            Invoke-InventoryResponseCleaner $response;
            $conf = Get-Config;

            # Assert
            $server = Get-Content $conf.serverPath | ConvertFrom-Json;
            $server.Count | Should -be $correctCount;
            $server[0] | Should -Be $hostname1;
            $server[1] | Should -Be $hostname2;
        }

        It "should only carry on with SRV*-Servers and where a Mgnt_Hostname exists" {
            # Arrange
            $response = $inventoryAnswer | ConvertFrom-Json -Depth 5;
            $small = @();
            foreach ($srv in $response.d.Rows) {
                $small += @{
                    Label         = $srv[0]
                    Hostname_Mgnt = $srv[2];
                }
            }
            $completeCount = $small.Count;
            $withSRVCount = ($small | Where-Object { $_.Label -match "SRV*" -and $_.Hostname_Mgnt } ).Count;
            
            # Act
            Invoke-InventoryResponseCleaner $response;
            $conf = Get-Config;
            $server = Get-Content $conf.serverPath | ConvertFrom-Json;

            # Assert
            $finalCount = ($server | Where-Object { $_.Label -match "SRV*" -and $_.Hostname_Mgnt }).Count;
            $finalCount | Should -BeLessOrEqual $withSRVCount;
            $completeCount | Should -Not -Be $server.Count
        }   
    }

    Context "Save-ServersFromInventory" {
        It "should create servers.json if not exists" {
            # Arrange
            [array]$serversToSave = @(
                "rmsrv01", "rmsrv02", "rmsrv03", "rmsrv04"
            )

            # Act
            Save-ServersFromInventory -ServersToSave $serversToSave;
            $srvPath = (Get-Config).serverPath;

            # Assert
            $serversAtEnd = Get-Content $srvPath -Force | ConvertFrom-Json;
            $serversAtEnd.Count | Should -Be ($serversToSave.Count);
            $srvPath | Should -Not -Be ($config.serverPath);
        }

        It "should throw error if no server path is configured." {
            # Arrange
            $serversToSave = @("srv01", "srv02");
            $err = "";
            Mock Update-Config { $config.serverPath = "" } -ModuleName "ILO-Inventorizer";

            # Act
            try {
                Save-ServersFromInventory -ServersToSave $serversToSave;
            }
            catch {
                $err = $_.Exception.Message.ToString();
            }
    
            # Assert
            $err | Should -Match "The server-path at '.*' could not be found. Please verify that the file exists\.";    
        }

    }
    AfterEach {
        $conf = Get-Config;
        if ($conf.serverPath -gt 0) {
            if (Test-Path $conf.serverPath) {
                Remove-Item $conf.serverPath -Force;
            }
        }
    }
}
AfterAll {
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}