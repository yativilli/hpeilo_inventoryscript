. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\General_Functions.ps1

Function Invoke-ParameterSetHandler{
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $ParameterSetName,

        [Parameter()]
        [string]
        $ConfigPath
    )

    switch ($ParameterSetName) {
        "Config" { 
            # Started with Path to Config as Parameter
            Log 6 "Started with 'Config' ParameterSet."
            Set-ConfigPath -Path $ConfigPath;
            break;
        }
        "ServerPath" {
            # Started with Path to Servers as Parameter
            Log 6 "Started with 'ServerPath' ParameterSet."
            $path = New-File -Path ($DEFAULT_PATH);
            New-Config $path -NotEmpty -WithOutInventory;
            Update-Config -DoNotSearchInventory $true;
            break;
        }
        "ServerArray" {
            # Started with Array of Servers as Parameter
            Log 6 "Started with 'ServerArray' ParameterSet."
            $path = New-File -Path ($DEFAULT_PATH);
            New-Config -Path $path -NotEmpty -WithOutInventory;
            Update-Config -DoNotSearchInventory $true;
            break;
        }
        "Inventory" {
            # Started with SearchStringInventory as Parameter
            Log 6 "Started with 'Inventory' ParameterSet."
            $path = New-File -Path ($DEFAULT_PATH);
            New-Config -Path $path -NotEmpty;
            break;
        }
        default {
            # Started without any Parameters that would trigger something different than an update to the configuration
    
            # No Config Found
            if ($ENV:HPEILOCONFIG.Length -eq 0) {
                Log 6 "Started without specific Parameterset - displaying configuration prompt."
                Write-Host "No Configuration has been found. Would you like to:`n[1] Generate an empty config? `n[2] Generate a config with dummy data?`n[3] Add Path to an Existing config?";
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
                        # Generate Config with Dummydata
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
                        $pathToConfig = Read-Host -Prompt "Where dou you have the config stored at?";
                        if (Test-Path $pathToConfig) {
                            Set-ConfigPath -Path $pathToConfig;
                        }
                        else {
                            throw [System.IO.FileNotFoundException] "The specified path $pathToConfig could not be found. Verify that it exists and contains a 'config.json'"
                        }
                        break;
                    }
                }
                return;   
            }
            elseif ($ENV:HPEILOCONFIG -gt 0) {

            }
            else {
                return;
            }
        }
    }
}