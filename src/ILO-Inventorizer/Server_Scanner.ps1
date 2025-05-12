. $PSScriptRoot\General_Functions.ps1
. $PSScriptRoot\Configuration_Functions.ps1
. $PSScriptRoot\Constants.ps1

Function Get-ServerByScanner {
    param(
        [Parameter()]
        [switch]
        $RequireSingleValidation,

        [Parameter()]
        [string]
        [ValidateNotNullOrEmpty()]
        $ReportPath,

        [Parameter()]
        [string]
        [ValidateNotNullOrEmpty()]
        $LogPath,

        [Parameter()]
        [switch]
        $KeepTemporaryConfig,

        [Parameter()]
        [int]
        $LogLevel = 0,

        [Parameter()]
        [switch]
        $LogToConsole,

        [Parameter()]
        [switch]
        $LoggingActivated,

        [Parameter()]
        [switch]
        $PingTestActivated,

        [Parameter()]
        [switch]
        $DeactivateCertificateValidation,

        [Parameter()]
        [switch]
        $IgnoreMACAddress,

        [Parameter()]
        [switch]
        $IgnoreSerialNumbers

    )
    try {
        Write-Host "------------------------`nStarted Scanner:`nTo capture any Server for ILO-Query, please scan the 'Password' and 'Hostname' printed on the Server itself with a barcode scanner."
        Write-Host "A Loop will run, prompting you to scan the 'Serial Number', 'Hostname' and 'Password' as many times as you please. `nATTENTION: Ensure that any hostname entered starts with 'Ilo'`nTo Stop the programme, please type 'exit'."

        ## Save Servers
        $servers = @();
        $iloCredentials = @();
        $serialNumbers = @();

        New-Config -Path ($DEFAULT_PATH_TEMPORARY) -ForScanner -StoreAsTemporary ;
        Update-Config -ReportPath (Get-ConfigPath) -LogPath $LogPath -LogLevel $LogLevel -LogToConsole:$LogToConsole -LoggingActivated:$LoggingActivated -DeactivatePingtest:$PingTestActivated -DeactivateCertificateValidation:$DeactivateCertificateValidation -IgnoreMACAddress:$IgnoreMACAddress -IgnoreSerialNumbers:$IgnoreSerialNumbers;

        ## Get Scanned Servers
        while ($true) {
            $res = Invoke-ScanServer;
            
            $servers += $res.Hostname;
            $iloCredentials += @{
                Username = $DEFAULT_USERNAME_ILO;
                Password = $res.Password;
            }
            $serialNumbers += $res.SerialNumber;
        }

        $config = Get-Config;
        $serverPath = $config.searchForFilesAt + "\scanned_servers.tmp";
        $servers | ConvertTo-Json -Depth 3 | Out-File -FilePath ($serverPath) -Force;
        Update-Config -ServerPath $serverPath

        $loginConfigPath = $config.LoginConfigPath;
        $iloCredentials | ConvertTo-Json -Depth 3 | Out-File -FilePath ($loginConfigPath) -Force;
        
        
        ## Query Scanned Servers 
        $report = @();
        for ([int]$i = 0; $i -le $servers.Count - 1; $i++) {
            Write-Host "`n-------------`nStart querying:"
            $server = $servers[$i];
            $username = $iloCredentials[$i].Username;
            $password = $iloCredentials[$i].Password;

            if ((Invoke-PingTest -Hostname $server -ErrorAction "SilentlyContinue") -and ($server.Length -gt 0 -and $username.Length -gt 0 -and $password.Length -gt 0)) {
                Log 2 "Server $server is reachable. Querying..." -IgnoreLogActive;
                # Call the function to query the server with the provided password
                $login = @{
                    Username = $username
                    Password = $password
                };
                $report += $server | Get-DataFromILO -Login $login;
                
                if ($null -ne $report) {

                    # Save the report
                    Save-DataInJSON -Report $report;
                    Save-DataInCSV -Report $report;
                    Log 2 "The Report has been saved at $($config.reportPath)" -IgnoreLogActive;
                }
            }
            else {
                Write-Host "Server $server is not reachable - check that it has been assigned a DNS-Entry (f.ex. in hosts-File). Skipping...";
                $mess = "Server '$server' not reachable";
                $server.Length -eq 0 ? ($mess += ": The Hostname is empty or wrong.") : $false | Out-Null;
                $username.Length -eq 0 ? ($mess += ": The Username is empty or wrong.") : $false | Out-Null;
                $password.Length -eq 0 ? ($mess += ": The Password is empty or wrong.") : $false | Out-Null;

                Add-Content -Path ($config.searchForFilesAt + $PART_DEFAULT_PATH_UNREACHABLE_SERVERS) -Value $mess -Force;
            }
        }
        if (-not $KeepTemporaryConfig) {
            Restore-Conditions;
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    
    }
}

Function Invoke-ScanServer {
    param()

    do {
        $serialNumber = Read-Host -Prompt "Please enter the Serial Number";
    }while ($serialNumber -eq "");
    $serialNumber | Stop-OnExit;

    do {
        $hostname = Read-Host -Prompt "Please enter the Hostname";
    } while ($hostname -eq "");
    $hostname | Stop-OnExit;
    
    do {
        $password = Read-Host -Prompt "Please enter the Password";
    } while ($password -eq "");
    $password | Stop-OnExit;
    $password = (ConvertTo-SecureString -String $password -AsPlainText -Force);

    $res = Resolve-ErrorsInInput -Hostname $hostname -Password $password -SerialNumber $serialNumber;

    $ping_res = Invoke-PingTest -Hostname $res.Hostname;
    $ping_res ? (Write-Host "Server $($res.Hostname) is reachable.`n") : (Write-Host "Server $($res.Hostname) is not reachable.`n");
    return $res;
}

Function Stop-OnExit {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $Object
    )
    if ($Object -contains "exit") {
        break;
    }
}

Function Resolve-ErrorsInInput {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $Hostname,

        [Parameter(ValueFromPipeline = $true)]
        [SecureString]
        $Password,

        [Parameter(ValueFromPipeline = $true)]
        [string]
        $SerialNumber
    )
    $expectedPassword = ($Password | ConvertFrom-SecureString -AsPlainText);
    $expectedPasswordLower = $($expectedPassword).ToLower();
    $expectedHostname = $($Hostname).ToLower();
    $expectedSerialNumber = $($SerialNumber).ToLower();
    $res = @{};

    # Filter Out Prod Id
    $expectedPasswordLower -like "-[A-Z][0-9]{2}" ? ($expectedPassword = $null) : $false;
    $expectedHostname -like "-[A-Z][0-9]{2}" ? ($expectedHostname = $null) : $false;
    $expectedSerialNumber -like "-[A-Z][0-9]{2}" ? ($expectedSerialNumber = $null) : $false;
    
    # Filter Hostname
    $expectedPasswordLower -like "ilo*" ? ($res["Hostname"] = ($expectedPassword)) : $false;
    $expectedHostname -like "ilo*" ? ($res["Hostname"] = ($Hostname)) : $false;
    $expectedSerialNumber -like "ilo*" ? ($res["Hostname"] = ($SerialNumber)) : $false;

    # Filter SerialNumber
    $expectedPasswordLower -notlike "ilo*" -and $expectedPasswordLower.Length -ge 9 ? ($res["SerialNumber"] = ($expectedPassword)) : $false;
    $expectedHostname -notlike "ilo*" -and $expectedHostname.Length -ge 9 ? ($res["SerialNumber"] = ($Hostname)) : $false;
    $expectedSerialNumber -notlike "ilo*" -and $expectedSerialNumber.Length -ge 9 ? ($res["SerialNumber"] = ($SerialNumber)) : $false;
    
    # Filter Password
    $expectedPasswordLower -notlike "ilo*" -and $expectedPasswordLower.Length -le 8 ? ($res["Password"] = ($expectedPassword)) : $false;
    $expectedHostname -notlike "ilo*" -and $expectedHostname.Length -le 8 ? ($res["Password"] = ($Hostname)) : $false;
    $expectedSerialNumber -notlike "ilo*" -and $expectedSerialNumber.Length -le 8 ? ($res["Password"] = ($SerialNumber)) : $false;

    return $res;
}

