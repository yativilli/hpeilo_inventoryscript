. $PSScriptRoot\Constants.ps1

Function Show-Help {
    param(
        [Parameter()]
        [string]
        $helpString
    )
    try {
        # Handle any Help if Requested via non-conventional means (like /? instead of Get-Help)
        if ($helpString.Length -gt 0) {
            switch ($helpstring) {
                { ($_ -eq "/?") -or ($_ -eq "--help") -or ($_ -eq "-h") } {
                    Log 5 "User has requested help -displaying Help-Page" 
                    return $true; 
                    break;
                }
                default {
                    return $false
                    break;
                }
            }
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Convert-PathsToValidated {
    param(
        [Parameter()]
        [switch]
        $IgnoreServerPath
    )

    try {
        # Validate that all Paths in Array exist
        Log 5 "Validating Paths..."
        $config = Get-Config;
        
        # searchForFilesAt-Property
        if (-not(Test-Path -Path ($config.searchForFilesAt))) {
            Log 6 ("`tCreating Path 'searchForFilesAt: " + $config.searchForFilesAt);
            New-Item -ItemType Directory ($config.searchForFilesAt) -Force | Out-Null;
        }

        # loginConfigPath-Property --> Error because path must be to a file -> the contents of which cannot be generated automatically
        if ((-not(Test-Path -Path ($config.loginConfigPath)))) {
            Log 6 ("`tPath 'loginConfigPath' does not exist: " + $config.loginConfigPath);
            throw [System.IO.FileNotFoundException] ("Path to '$path' could not be resolved. Verify that loginConfigPath includes some file like 'login.json' and it and the file must exist for the script to work. It also must include a Username and a Password.")
        }

        # serverPath-Property --> Error because path must be to a file -> the contents of which cannot be generated automatically
        if ((-not(Test-Path -Path ($config.serverPath))) -and ($IgnoreServerPath -eq $false)) {
            Log 6 ("`tPath 'serverPath' does not exist: " + $config.serverPath);
            throw [System.IO.FileNotFoundException] ("Path to '$path' could not be resolved. Verify that serverPath includes some file like 'server.json' and it and the file must exist for the script to work, with it containing an array of servers.")
        }

        # reportPath-Property
        if ((-not(Test-Path -Path ($config.reportPath)))) {
            Log 6 ("`tCreating Path 'reportPath: " + $config.reportPath);
            New-Item -ItemType Directory ($config.reportPath) -Force | Out-Null;
        }

        # logPath-Property
        if ((-not(Test-Path -Path ($config.logPath)))) {
            Log 6 ("`tCreating Path 'logPath: " + $config.logPath);
            New-Item -ItemType Directory ($config.logPath) -Force | Out-Null;
        }
        Log 5 "Paths validated."
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}


Function New-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )
    try {
        # Create new File at Path
        Log 5 "Create new File at $Path";
        if ((Test-Path -Path $Path) -eq $false) {
            New-Item -ItemType File -Path $Path -Force -ErrorAction Stop;
        }
        return $Path;
    }
    catch [System.IO.DirectoryNotFoundException], [System.IO.FileNotFoundException] {
        Save-Exception $_ ("The Path '$Path' could not be found. Please verify that it exists and doesn't point to nowhere.")
    }
}

Function Save-Exception {
    param(
        [Parameter(Mandatory = $true)]
        $_,

        [Parameter(Mandatory = $true)]
        $Message
    )
    # Save Exceptions to Logs and log them to the console
    Log 1 ("$Message`n" + $_.ScriptStackTrace);
    Write-Error ("$Message");
}

Function Get-Config {
    <#
    .SYNOPSIS
    Returns the current Config
    .DESCRIPTION
    If called, it will read the current config-path and convert it from JSON back to a PS-Object. 
    .EXAMPLE
    PS> Get-Config
    searchForFilesAt                : C:\Users\wernle_y\AppData\Roaming\hpeilo
    configPath                      : C:\Users\wernle_y\AppData\Roaming\hpeilo\config.json
    loginConfigPath                 : C:\Users\wernle_y\AppData\Roaming\hpeilo\login.json
    reportPath                      : C:\Users\wernle_y\AppData\Roaming\hpeilo\out
    serverPath                      : C:\Users\wernle_y\AppData\Roaming\hpeilo\server.json
    logPath                         : C:\Users\wernle_y\AppData\Roaming\hpeilo\logs
    logLevel                        : 0
    loggingActivated                  : True
    searchStringInventory           : gfa-sioc-cs-de
    doNotSearchInventory            : False
    remoteMgmntField                : Hostname Mgnt
    deactivateCertificateValidation : True
    logToConsole                    : False
    ignoreMACAddress                : False
    ignoreSerialNumbers             : False
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param (
        # Show Help if Value is /? or --help
        [Parameter(Position = 0)][string]$help,
        # Show Help if Value is true
        [Parameter()][switch]$h
    )
    try {
        if (($h ) -or ((Show-Help $help) -and ($help.Length -gt 0)) ) {
            Get-Help Get-Config -Full;    
        }
        # Log 5 "Getting Configuration..."
        else {   
            if ((Test-Path -Path $ENV:HPEILOCONFIG)) {
                $config = (Get-Content $ENV:HPEILOCONFIG | ConvertFrom-Json -Depth 3);

                Log 6 "`tValidating Configuration..."
                # Validate Types of Configuration --> Exception for Serverpath and searchStringInventory since they can be null if the other one is not 
                Invoke-ConfigTypeValidation -Config $config;
                
                Log 5 "Configuration successfully read and will be returned..."
                return $config;
            }
            else {
                throw [System.IO.FileNotFoundException] "No config has been specified. Use either Set-ConfigPath to set Path to an existing one or let one generate by using Get-NewConfig";
            }
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Invoke-ConfigTypeValidation {
    param(
        [Parameter(Mandatory)]
        [System.Object]$Config
    )
    # Type in Order of Configuration: Ordered
    $expectedType = @(
        [string], [string], [string], [string], [string], [string], [Int64], [string], [string], [bool], [bool], [bool], [bool], [bool], [bool], [bool]
    )
    [int]$i = 0;
    foreach ($key in $Config.Keys) {
        $type = $expectedType[$i];
        Invoke-TypeValidation -ExpectedType $type -Value ($Config[$key]) -Name $key;
        $i++;
    }
}

Function Invoke-TypeValidation {
    param(
        [type]$ExpectedType,
        [System.Object]$Value,
        [string]$Name
    )
    $valueType = $Value.GetType();
    if ($ExpectedType -ne $valueType) {
        throw [System.IO.InvalidDataException] "Your configuration has wrong types: '$Name' must be of type '$ExpectedType' but is instead of type '$valueType'. Please change your configuration and/or Parameters to match the Type '$ExpectedType'";
    }
}

Function Log {
    param(
        [Parameter(Mandatory = $true)]
        [int]
        $Level,

        [Parameter(Mandatory = $true)]
        [string]
        $Message,
        
        [Parameter()]
        [switch]
        $IgnoreLogActive
    )
    try {
        $currentDateTime = Get-Date -Format "yyyy/MM/dd HH:mm:ss`t";
        $saveString = $currentDateTime + $Message;
        
        # If Config Exists
        if (($ENV:HPEILOCONFIG.Length -gt 0) -and (Test-Path -Path $ENV:HPEILOCONFIG)) {
            $config = (Get-Content $ENV:HPEILOCONFIG | ConvertFrom-Json -Depth 3);

            $logPath = $config.logPath;
            $logLevel = $config.logLevel;
            # LogLevel is NaN
            Invoke-TypeValidation -ExpectedType ([Int64]) -Value $logLevel -Name "logLevel"
            $logActive = $config.loggingActivated;
            $logToConsoleActive = $config.logToConsole;

            # No LogPath is set
            if ($logPath.Length -gt 0) {
                if (-not (Test-Path -Path $logPath)) { throw [System.IO.DirectoryNotFoundException] "Your provided logPath '$logPath' could not be found. Verify it exists" }
            }            
            
            # Log only if activated
            if ($logActive -or $IgnoreLogActive) {
                if ($Level -le $logLevel -or $IgnoreLogActive) {
                    if ((Test-Path -Path $logPath) -eq $false) {
                        throw [System.IO.DirectoryNotFoundException] "Your provided Path '$logPath' could not be found. Verify it exists"
                    }
                    $logFilePath = "$logPath\" + (Get-Date -Format $DATE_FILENAME) + ".txt";

                    # Add to File if already exists
                    if (Test-Path -Path $logFilePath) {
                        Add-Content -Path $logFilePath -Value $saveString;
                    }
                    else {
                        # File does not exist, create new
                        Set-Content -Path $logFilePath -Value $saveString -Force;
                    }
                    
                    # Write to Terminal if configured
                    if ($logToConsoleActive -or $IgnoreLogActive) {
                        Write-Host ($saveString);
                    }
                }
            }
        }
        else {
            # Warning if no Logfile exists (yet)
            Write-Warning "No path to logfiles exist. Please specify one in your config or via parameter as soon as possible.";
        }
    }
    catch {
        Write-Error $_ ($_.Exception.Message.ToString());
    }
}

Function Invoke-PingTest {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Hostname
    )
    try {
        Log 5 "Starting Pingtest";
        Log 6 "`tExecute Nslookup on $Hostname"
        # Execute nslookup
        $nsl = Resolve-DnsName $Hostname -ErrorAction SilentlyContinue;
        if ($nsl.Length -gt 0) {
            $dnsname = $nsl.Name;   
            # Reachable via NSLookup, but insufficient permissions for Ping
            if ((Test-Connection $dnsname -Count 1 -Quiet) -eq $false) {
                Log 2 "$Hostname was found via nslookup but could not be reached. Verify that you have appropriate permissions within your network to access it."
                return $false
            }
            # Reachable with Ping
            else {
                Log 6 "`tPingtest executed successfully"
                return $true; 
            }
        }
        else {
            # Not Reachable via NSlookup
            Log 2 "$Hostname is not reachable from within this network and could not be found via nslookup."
            return $false
        }
    }
    catch {    
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Resolve-NullValuesToSymbol {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Value
    )
    Resolve-NullValues -Value $Value -ValueOnNull $NO_VALUE_FOUND_SYMBOL;
}

Function Resolve-NullValues {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Value,

        [Parameter(ValueFromPipeline = $false)]
        $ValueOnNull
    )
    if (($null -eq $Value) -or ($Value.Length -le 0)) {
        return $ValueOnNull;
    }
    return $Value
}