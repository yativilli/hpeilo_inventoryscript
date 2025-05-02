. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\General_Functions.ps1
. $PSScriptRoot\Configuration_Functions.ps1

Function Invoke-ParameterSetHandler {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $ParameterSetName,

        [Parameter()]
        [string]
        $ConfigPath,

        [Parameter()]
        [string]
        $LoginPath
    )

    switch ($ParameterSetName) {
        "Config" { 
            # Started with Path to Config as Parameter
            Log 6 "Started with 'Config' ParameterSet."
            Set-ConfigPath -Path $ConfigPath;
            return;
        }
        "ServerPath" {
            # Started with Path to Servers as Parameter
            Log 6 "Started with 'ServerPath' ParameterSet."
            New-Config $DEFAULT_PATH_TEMPORARY -NotEmpty -WithOutInventory -StoreAsTemporary -LoginPath $LoginPath;
            Update-Config -DoNotSearchInventory $true;
            break;
        }
        "ServerArray" {
            # Started with Array of Servers as Parameter
            Log 6 "Started with 'ServerArray' ParameterSet."
            New-Config -Path $DEFAULT_PATH_TEMPORARY -NotEmpty -WithOutInventory -StoreAsTemporary -LoginPath $LoginPath;
            Update-Config -DoNotSearchInventory $true;
            break;
        }
        "Inventory" {
            # Started with SearchStringInventory as Parameter
            Log 6 "Started with 'Inventory' ParameterSet."
            New-Config -Path $DEFAULT_PATH_TEMPORARY -NotEmpty -StoreAsTemporary -LoginPath $LoginPath;
            break;
        }
        default {
            # No Config Found
            if ($ENV:HPEILOCONFIG.Length -eq 0) {
                Invoke-NoConfigFoundHandler;
            }
            else {
                return;
            }
        }
    }
}

Function Invoke-NoConfigFoundHandler {
    param()

    Log 6 "Started without specific Parameterset - displaying configuration prompt."
    Write-Host "No Configuration has been found. Would you like to:`n[1] Generate an empty config? `n[2] Generate a config with example data?`n[3] Add Path to an Existing config?";
    [int]$configDecision = Read-Host -Prompt "Enter the corresponding number:";
 
    switch ($configDecision) {
        1 {
            # Generate Empty Config
            Log 6 "User has selected generating empty config"
            $pathToSaveAt = Read-Host -Prompt "Where do you want to save the config at?";
            if ((Test-Path $pathToSaveAt) -eq $false) { throw [System.IO.DirectoryNotFoundException] "The path provided ('$pathToSaveAt') does not exist. Verify that it does" }
            New-Config -Path $pathToSaveAt;
            break;
        }
        2 {
            # Generate Config with exampledata
            Log 6 "User has selected generating a config with dumydata."
            $pathToSaveAt = Read-Host -Prompt "Where do you want to save the config at?";
            if ((Test-Path $pathToSaveAt) -eq $false) { throw [System.IO.DirectoryNotFoundException] "The path provided ('$pathToSaveAt') does not exist. Verify that it does" }
            $withInventory = Read-Host -Prompt "Do you want to:`nRead From Inventory [y/N]?"
            switch ($withInventory) {
                "y" {
                    # Generate with Inventory-Preset
                    New-Config -Path $pathToSaveAt -NotEmpty;
                    break;
                }
                "N" {
                    # Generate with ServerPath-Preset
                    New-Config -Path $pathToSaveAt -WithoutInventory -NotEmpty;
                    break;
                }
            }
            break;
        }
        3 {
            # Add Path to Config
            Log 6 "User has selected adding existing config"
            $pathToConfig = Read-Host -Prompt "Where do you have the config stored at?";
            if (Test-Path $pathToConfig) {
                Set-ConfigPath -Path $pathToConfig;
            }
            else {
                throw [System.IO.FileNotFoundException] "The specified path $pathToConfig could not be found. Verify that it exists and contains a 'config.json'"
            }
            break;
        }
    }
}

Function Start-PingtestOnServers {
    [Array]$reachable = @();
    $config = Get-Config;
    $serverJSON = Get-Content ($config.serverPath) | ConvertFrom-JSON -Depth 2;
    if (-not $config.deactivatePingtest) {
        Log 3 "Start Pingtest"
        foreach ($srv in $serverJSON) {
            if (Invoke-PingTest $srv) {
                Log 0 "$srv was successfully reached via Pingtest." -IgnoreLogActive;
                $reachable += $srv;
            }
            else {
                Log 0 "$srv was not able to be reached via Pingtest." -IgnoreLogActive;
            }
        }
    }
    else {
        $reachable = $serverJSON;
    }
    return $reachable;
}

Function Optimize-ParameterStartedForUpdate {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $BoundParameters
    )
    $config = Get-Config; 
    $login = (Get-Content ($config.loginConfigPath) | ConvertFrom-Json -Depth 3);
 
    Update-Config -ConfigPath ($BoundParameters["ConfigPath"] | Resolve-NullValues -ValueOnNull $config.configPath) -LoginConfigPath ($BoundParameters["LoginConfigPath"] | Resolve-NullValues -ValueOnNull $config.loginConfigPath) -ReportPath ($BoundParameters["ReportPath"] | Resolve-NullValues -ValueOnNull $config.reportPath) -LogPath ($BoundParameters["LogPath"] | Resolve-NullValues -ValueOnNull $config.logPath)  -ServerPath ($BoundParameters["ServerPath"] | Resolve-NullValues -ValueOnNull $config.serverPath)  -Server ($BoundParameters["Server"]) -LogLevel  ($BoundParameters["LogLevel"] | Resolve-NullValues -ValueOnNull $config.logLevel) -DeactivatePingtest:($BoundParameters["DeactivatePingtest"] | Resolve-NullValues -ValueOnNull $config.deactivatePingtest)  -IgnoreMACAddress:($BoundParameters["IgnoreMACAddress"] | Resolve-NullValues -ValueOnNull $config.ignoreMACAddress) -IgnoreSerialNumbers($BoundParameters["IgnoreSerialNumbers"] | Resolve-NullValues -ValueOnNull $config.ignoreSerialNumbers)  -LogToConsole:($BoundParameters["LogToConsole"] | Resolve-NullValues  -ValueOnNull $config.logToConsole) -LoggingActivated:($BoundParameters["LoggingActivated"] | Resolve-NullValues -ValueOnNull $config.loggingActivated) -SearchStringInventory ($BoundParameters["SearchStringInventory"] | Resolve-NullValues -ValueOnNull $config.searchStringInventory) -DoNotSearchInventory:($BoundParameters["DoNotSearchInventory"] | Resolve-NullValues -ValueOnNull $config.doNotSearchInventory) -RemoteMgmntField ($BoundParameters["RemoteMgmntField"] | Resolve-NullValues -ValueOnNull $config.remoteMgmntField) -DeactivateCertificateValidationILO:($BoundParameters["DeactivateCertificateValidationILO"] | Resolve-NullValues -ValueOnNull $config.deactivateCertificateValidation) -Username ($BoundParameters["Username"] | Resolve-NullValues -ValueOnNull $login[0].Username) -Password ($BoundParameters["Password"] | Resolve-NullValues -ValueOnNull (ConvertTo-SecureString -String ($login[0].Password) -AsPlainText));
}