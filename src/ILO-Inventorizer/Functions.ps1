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

Function Generate-Config {
    param(
        [Parameter(Mandatory = $true)]
        [ParameterType]
        $Path,


        [Parameter()]
        [switch]
        $NotEmpty,

        [Parameter()]
        [switch]
        $WithOutInventory
    )

    $config = [ordered]@{
        searchForFilesAt = $Path;
        $configPath = ($Path + "\config.json")
        $loginConfigPath = $log_config
        $reportPath = $report_path
        $serverPath = $server_path
        $logPath = $log_path
        $logLevel = $log_level
        $loggingActived = $logging_activated
        $searchStringInventory = $search_string_inventory
        $doNotSearchInventory = $do_not_search_inventory
        $remoteMgmntField = $remote_mgmnt_field
        $deactivateCertificateValidation = $deactivate_certificate_validation
    }

    $login = [ordered]@{
        $Username = $user_name
        $Password = $pass_word
    }
}