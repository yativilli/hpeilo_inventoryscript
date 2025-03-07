Function Show-Help {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $h
    )
    if (($h -eq "/?") -or ($h -eq "-h") -or ($h -eq "--help") -or ($h -eq "--h")) {
        Write-Host "Display-Help";
        Get-Help GetHWInfoFromILO -Full
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
    }
    
    $login = [ordered]@{
        Username = ""
        Password = ""
    }
        
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
    Write-Host $env:hpeiloConfig;
}