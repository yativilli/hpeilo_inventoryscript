Function Show-Help {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $h
    )
    if (($h -eq "/?") -or ($h -eq "-h") -or ($h -eq "--help")) {
        Write-Host "Display-Help";
        Get-Help GetHWInfoFromILO -Full
        return;
    }
}