. $PSScriptRoot\General_Functions.ps1
. $PSScriptRoot\Configuration_Functions.ps1
. $PSScriptRoot\Constants.ps1

Function Get-ServerByScanner {
    param(

    )
    Write-Host "------------------------`nStarted Scanner:`nTo capture any Server for ILO-Query, please scan the 'Password' and 'Hostname' printed on the Server itself with a barcode scanner."
    Write-Host "A Loop will run, prompting you to scan the 'Password' and 'Hostname' of the Server as many times as you please. `nTo Stop the programme, please type 'exit'."

    ## Save Servers
    $i = 0;
    $servers = @();
    $passwords = @();
    
    while ($true) {
        do {
            $hostname = Read-Host -Prompt "Please enter the Hostname";
        } while ($hostname -eq "");
        $hostname | Stop-OnExit;
        $servers += $hostname;

        do {
            $password = Read-Host -Prompt "Please enter the Password";
        } while ($password -eq "");
        $password | Stop-OnExit;
        $passwords += $password;
    }

    ## Execute 

    for ([int]$i = 0; $i -le $servers.Count - 1; $i++) {
        $server = $servers[$i];
        $password = $passwords[$i];

        Write-Host "Server: $server, Password: $password";
        Write-Host (Invoke-PingTest -Hostname $server);
        # Call the function to query the server with the provided password
        $rep = Get-DataFromILO -Servers $server -Username "Yannik" -Password (ConvertTo-SecureString -String $password -AsPlainText -Force);
        Save-DataInJSON -Report $rep;
        Save-DataInCSV -Report $rep;
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