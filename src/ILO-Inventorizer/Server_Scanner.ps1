. $PSScriptRoot\General_Functions.ps1
. $PSScriptRoot\Configuration_Functions.ps1
. $PSScriptRoot\Constants.ps1

Function Get-ServerByScanner {
    param(

    )
    try {

        Write-Host "------------------------`nStarted Scanner:`nTo capture any Server for ILO-Query, please scan the 'Password' and 'Hostname' printed on the Server itself with a barcode scanner."
        Write-Host "A Loop will run, prompting you to scan the 'Serial Number', 'Hostname' and 'Password' as many times as you please. `nATTENTION: Ensure that any hostname entered starts with 'Ilo'`nTo Stop the programme, please type 'exit'."

        ## Save Servers
        $servers = @();
        $passwords = @();

        New-Config -Path ($DEFAULT_PATH + "\Scanner") -ForScanner | Out-Null;

        ## Get Scanned Servers
        while ($true) {
            do {
                $serialNumber = Read-Host -Prompt "Please enter the Serial Number";
            }while ($serialNumber -eq "");
            $serialNumber | Stop-OnExit;

            do {
                $hostname = Read-Host -Prompt "Please enter the Hostname";
            } while ($hostname -eq "" -or $password -eq "exit");
            
            do {
                $password = Read-Host -Prompt "Please enter the Password";
            } while ($password -eq "" -or $password -eq "exit");
            $password = (ConvertTo-SecureString -String $password -AsPlainText -Force);
    

            $res = Resolve-ErrorsInInput -Hostname $hostname -Password $password -SerialNumber $serialNumber;
            Write-Host "---`nScanned Information:`nHostname: $($res.Hostname)`nSerial Number: $($res.SerialNumber)`nPassword: $($res.Password)";

            do {
                $corr = Read-Host -Prompt "---`nIs the scanned information correct? [y/N]";
            } while ($corr -ne "y" -and $corr -ne "N");

            if ($corr -eq "y") {
                $servers += $res.Hostname;
                $passwords += $res.Password;
            }
            else {
                Write-Host "Please scan the information again.";
            }
        }

        ## Query Scanned Servers 
        $report = @();
        for ([int]$i = 0; $i -le $servers.Count - 1; $i++) {
            $server = $servers[$i];
            $password = $passwords[$i];

            Write-Host "Server: $server, Password: $password";
            if (Invoke-PingTest -Hostname $server) {
                # Call the function to query the server with the provided password
                $report += Get-DataFromILO -Servers $server -Username $DEFAULT_USERNAME_ILO -Password $password;
                
                # Save the report
                Save-DataInJSON -Report $report;
                Save-DataInCSV -Report $report;
                Log 2 "The Report has been saved at $DEFAULT_PATH"
            }
            else {
                Write-Host "Server $server is not reachable - check that it has been assigned a DNS-Entry (f.ex. in hosts-File). Skipping...";
            }
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Stop-OnExit {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [psobject]
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

    if ($null -eq $res["Password"]) {
        throw [System.IO.InvalidDataException]
    }
    elseif ($null -eq $res["Hostname"]) {
        if ($null -eq $res["SerialNumber"]) {
            throw [System.IO.InvalidDataException]
        }
        else {
            $res["Hostname"] = ("ILO" + $res["SerialNumber"]);
        }
    }
    elseif ($null -eq $res["SerialNumber"]) {
        if ($null -eq $res["Hostname"]) {
            throw [System.IO.InvalidDataException]
        }
        else {
            $res["SerialNumber"] = ($res["Hostname"]).replace("ILO", "");
        }
    }

    return $res;
}