. $PSScriptRoot\General_Functions.ps1
. $PSScriptRoot\Configuration_Functions.ps1
. $PSScriptRoot\Constants.ps1

Function Get-ServerByScanner{
    param(

    )

    ## Generate Configuration
    New-Config -Path ($DEFAULT_PATH + "\Scanner") -NotEmpty -WithOutInventory
    Update-Config -LogToConsole

    ## Save to Server
    $i = 0;
    do{


        $i++;
    }while ($i -lt 10)


    ## Execute 

}