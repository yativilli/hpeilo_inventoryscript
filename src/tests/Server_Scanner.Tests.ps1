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

Describe "Server_Scanner" {
    Context "Invoke-ScanServer" {
        It "should ask for serialnumber, hostname and password" {
            # Arrange
            Mock Read-Host { return "CZ0120310"; } -ParameterFilter { ($Prompt -join '').Contains("Please enter the Serial Number") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return "ILOCZ0120310"; } -ParameterFilter { ($Prompt -join '').Contains("Please enter the Hostname") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return "12345678"; } -ParameterFilter { ($Prompt -join '').Contains("Please enter the Password") } -ModuleName "ILO-Inventorizer";
            
            Mock Invoke-PingTest { return $true; } -ModuleName "ILO-Inventorizer";

            # Act
            $response = Invoke-ScanServer
            # Assert
            $res = @{
                Hostname     = "ILOCZ0120310"
                Password     = "12345678"
                SerialNumber = "CZ0120310";
            }
           
            foreach ($key in $response.Keys) {
                $i = ([array]$response.Keys).IndexOf($key);
                $response.Values[$i] | Should -Be $res[$key];
            }
        }

        It "should resolve errors in order" {
            # Arrange
            Mock Read-Host { return "12345678"; } -ParameterFilter { ($Prompt -join '').Contains("Please enter the Serial Number") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return "CZ0120310"; } -ParameterFilter { ($Prompt -join '').Contains("Please enter the Hostname") } -ModuleName "ILO-Inventorizer"; 
            Mock Read-Host { return "ILOCZ0120310"; } -ParameterFilter { ($Prompt -join '').Contains("Please enter the Password") } -ModuleName "ILO-Inventorizer";
            
            Mock Invoke-PingTest { return $true; } -ModuleName "ILO-Inventorizer";

            # Act
            $response = Invoke-ScanServer
            # Assert
            $res = @{
                Hostname     = "ILOCZ0120310"
                Password     = "12345678"
                SerialNumber = "CZ0120310";
            }
           
            foreach ($key in $response.Keys) {
                $i = ([array]$response.Keys).IndexOf($key);
                $response.Values[$i] | Should -Be $res[$key];
            }
            Should -Invoke -CommandName "Invoke-Pingtest" -Times 1 -ModuleName "ILO-Inventorizer";
        }

        It "should stop on 'exit'" {
            # Arrange
            Mock Read-Host { return "12345678"; } -ParameterFilter { ($Prompt -join '').Contains("Please enter the Serial Number") } -ModuleName "ILO-Inventorizer";
            Mock Read-Host { return "exit" } -ParameterFilter { ($Prompt -join '').Contains("Please enter the Hostname") } -ModuleName "ILO-Inventorizer"; 
            Mock Read-Host {  } -ParameterFilter { ($Prompt -join '').Contains("Please enter the Password") } -ModuleName "ILO-Inventorizer";
            Mock Invoke-PingTest {  } -ModuleName "ILO-Inventorizer";
            
            # Act
            $i = 0;
            while ($i -lt 4) {
                $response = Invoke-ScanServer 
                $i++;
            }

            # Assert
            $i | Should -Be 0;
            ($response -eq $null) | Should -Be $true
            Should -Invoke "Invoke-PingTest" -Times 0 -ModuleName "ILO-Inventorizer";

        }
    }

    Context "Stop-OnExit" {
        It "should stop if input is exit" {
            # Arrange
            $inputs = @("some", "someother", "exit", "something");
            $expectedIndex = 2;

            # Act
            for ($i = 0; $i -le ($inputs.Length - 1); $i++) {
                $inputs[$i] | Stop-OnExit
            }

            # Assert
            $i | Should -Be $expectedIndex;
        }
        
        It "should not break if input is not exit" {
            # Arrange
            $inputs = @("some", "someother", "somethingMinor", "something");
            $expectedIndex = $inputs.Length - 1;

            # Act
            for ($i = 0; $i -lt ($inputs.Length - 1); $i++) {
                $inputs[$i] | Stop-OnExit
            }

            # Assert
            $i | Should -Be $expectedIndex;
        }
    }

    Context "Resolve-ErrorsInInput" {
        It "should filter out prod-id" {
            # Arrange
            $hostname = "ASBDS-D23";
            $password = ConvertTo-SecureString -String "12313211" -AsPlainText;
            $serialnumber = "CZ2010197";

            # Act
            $res = Resolve-ErrorsInInput -Hostname $hostname -Password $password -SerialNumber $serialnumber;

            # Assert
            ($res["Hostname"] -eq $null) | Should -Be $true;
        }

        It "should bring false inputs in correct order" {
            # Arrange
            $res = @{
                Hostname     = "ILOCZ0120310"
                Password     = "12345678"
                SerialNumber = "CZ0120310";
            }
   
            # Act
            $response = Resolve-ErrorsInInput -Hostname $res.SerialNumber -Password (ConvertTo-SecureString -String $res.Password -AsPlainText) -SerialNumber $res.Hostname;

            foreach ($key in $response.Keys) {
                $i = ([array]$response.Keys).IndexOf($key);
                $response.Values[$i] | Should -Be $res[$key];
            }
        }
    }       
}
AfterAll {
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}