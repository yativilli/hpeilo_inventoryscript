Function Show-Help {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $h
    )
    if (($h -eq "/?") -or ($h -eq "-h") -or ($h -eq "--help") -or ($h -eq "--h")) {
        Write-Host "Display-Help";
        Get-Help Get-HWInfoFromILO -Full
        return;
    }
}

Function New-Config {
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $Path,
        
        [Parameter()]
        [switch]
        $NotEmpty,
        
        [Parameter()]
        [switch]
        $WithOutInventory
    )
    $config_path = ($Path + "\config.json");
    $login_config_path = ($Path + "\login.json");
    $config = [ordered]@{
        searchForFilesAt                = $Path
        configPath                      = $config_path
        loginConfigPath                 = $login_config_path
        reportPath                      = ""
        serverPath                      = ""
        logPath                         = ""
        logLevel                        = ""
        loggingActived                  = ""
        searchStringInventory           = ""
        doNotSearchInventory            = $false
        remoteMgmntField                = ""
        deactivateCertificateValidation = $false
    };
    
    $login = [ordered]@{
        Username = ""
        Password = ""
    };
        
    ## Generate Dummy (w/o Inventory)
    if ($NotEmpty -and $WithOutInventory) {
        $config.reportPath = $Path + "\reports";
        $config.serverPath = $Path + "\servers.json";
        $config.logPath = $Path + "\logs";
        $config.logLevel = 0;
        $config.loggingActived = $true;
        $config.searchStringInventory = "";
        $config.doNotSearchInventory = $true;
        $config.remoteMgmntField = "";
        $config.deactivateCertificateValidation = $true;

        $login.Username = "SomeFancyUsername";
        $login.Password = "SomeFancyPassword";

        $servers = @("rmgfa-sioc-cs-dev", "rmgfa-sioc-cs-de3", "rmgfa-sioc-de4", "rmdl20test");

        $servers | ConvertTo-Json -Depth 2 | Out-File -FilePath ($Path + "\server.json");
    }
    ## Generate Dummy (w/ Inventory)
    elseif ($NotEmpty) {
        $config.reportPath = $Path + "\reports";
        $config.serverPath = "";
        $config.logPath = $Path + "\logs";
        $config.logLevel = 0;
        $config.loggingActived = $true;
        $config.searchStringInventory = "rmgfa-sioc-cs";
        $config.doNotSearchInventory = $false;
        $config.remoteMgmntField = "Hostname Mgnt";
        $config.deactivateCertificateValidation = $true;

        $login.Username = "SomeFancyUsername";
        $login.Password = "SomeFancyPassword";
    }
    ## Generate empty
    else {
        $config.reportPath = "";
        $config.serverPath = "";
        $config.logPath = "";
        $config.logLevel = 0;
        $config.loggingActived = $null;
        $config.searchStringInventory = "";
        $config.doNotSearchInventory = $null;
        $config.remoteMgmntField = "";
        $config.deactivateCertificateValidation = $null;

        $login.Username = "";
        $login.Password = "";
    }

    $config | ConvertTo-Json -Depth 2 | Out-File -FilePath $config_path;
    $login | ConvertTo-Json -Depth 2 | Out-File -FilePath ($Path + "\login.json");
    Set-ConfigPath -Path $config_path;
    Write-Host $ENV:HPEILOCONFIG;
}

Function New-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    if (Test-Path -Path $Path -eq $false) {
        New-Item -Path $Path -Force;
    }
    return $Path;
}

Function Update-Config {
    param(
        [Parameter()]
        [string]
        $configPath,

        [Parameter()]
        [string]
        $LoginConfigPath,

        [Parameter()]
        [string]
        $ReportPath,

        [Parameter()]
        [string]
        $LogPath,

        [Parameter()]
        [string]
        $ServerPath,

        [Parameter()]
        [array]
        $server,

        [Parameter()]
        [int]
        $LogLevel = -1,

        [Parameter()]
        [bool]
        $LoggingActivated = $null,

        [Parameter()]
        [string]
        $SearchStringInventory,

        [Parameter()]
        [bool]
        $DoNotSearchInventory = $null,

        [Parameter()]
        [string]
        $RemoteMgmntField,

        [Parameter()]
        [bool]
        $DeactivateCertificateValidationILO = $null,

        [Parameter()]
        [string]
        $Username,

        [Parameter()]
        [securestring]
        $Password
    )

    $pathToConfig = $ENV:HPEILOCONFIG;
    if (Test-Path -Path $pathToConfig) {
        $config = Get-Content -Path $pathToConfig | ConvertFrom-Json -Depth 3;

        if ($null -ne $configPath) { $config.configPath = $configPath; }
        if ($null -ne $LoginConfigPath) { $config.loginConfigPath = $LoginConfigPath; }
        if ($null -ne $ReportPath) { $config.reportPath = $ReportPath; }
        if ($null -ne $LogPath) { $config.logPath = $LogPath; }
        if ($null -ne $ServerPath) { $config.serverPath = $ServerPath; }
        if ($LogLevel -ne -1) { $config.logLevel = $LogLevel; }
        if ($null -ne $SearchStringInventory) { $config.searchStringInventory = $SearchStringInventory; }
        if ($null -ne $RemoteMgmntField) { $config.remoteMgmntField = $RemoteMgmntField; }

        # Set Switch-Value
        if ($null -ne $LoggingActivated) { $config.loggingActived = $true; }
        if ($null -ne $DoNotSearchInventory) { $config.doNotSearchInventory = $true; }
        if ($null -ne $DeactivateCertificateValidationILO) { $config.deactivateCertificateValidationILO = $true; }

        # Set ServerArray
        if ($server.Length -gt 0) { 
            if (Test-Path -Path $config.serverPath) {

            } 
            else {
                $serverPath = New-File ($defaultPath + "\server.json"); 
                $config.serverPath = $ServerPath;

                Set-Content -Path $ServerPath -Value ($server | ConvertTo-JSOn -Depth 2);
            }
        }
        
        # Set Credentials
        $login = Get-Content -Path ($config.logConfigPath) | ConvertFrom-Json -Depth 3;
        if ($null -ne $Username) { $login.Username = $Username; }
        if ($null -ne $Password) { $login.Password = $Password }
    }
    else {
        throw [System.IO.FileNotFoundException] "No updatable config could be found at $pathToConfig";
    }
}