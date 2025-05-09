. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\General_Functions.ps1
. $PSScriptRoot\QueryILO_Functions.ps1
. $PSScriptRoot\Configuration_Functions.ps1

Function Get-DataFromILO {
    param(
        # Array with all the Hostnames of the Servers that will be querried
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [Array]
        $Servers,

        [Parameter(Mandatory = $true)]
        [Array]
        $Login
    )
    try {
        $report = @();
        [int]$i = 0;
        foreach ($srv in $Servers) {
            Log 6 "Started querying $srv" -IgnoreLogActive

            $log = $Login[$i]
            if($null -eq $log){
                $log = $Login[($i -1)]
            }
            
            # Make connection with ILO.
            $conn = Connect-HPEiLO -Address $srv -Username ($log.Username) -Password ($log.Password) -DisableCertificateAuthentication:($config.deactivateCertificateValidation) -ErrorAction Stop;
            
            # Get MAC 1 to MAC 4 from NetworkAdapters --> to look exactly like Inventory
            
            # Structure Report nicely and add it to array
            $srvReport = [ordered]@{
                Serial            = $findILO.SerialNumber;
                Part_Type_Name    = $conn.TargetInfo.ProductName;
                Hostname          = ($conn | Get-HPEiLOAccessSetting).ServerName.ToLower();
                Hostname_Mgnt     = $conn.Hostname.ToLower();
                ILO_Version       = ([regex]"\d").Match((Find-HPEiLO $srv).PN).Value;
                MAC_1             = ($conn | Format-MACAddressesLikeInventory).MAC1;
                MAC_2             = ($conn | Format-MACAddressesLikeInventory).MAC2;
                MAC_3             = ($conn | Format-MACAddressesLikeInventory).MAC3;
                MAC_4             = ($conn | Format-MACAddressesLikeInventory).MAC4;
                Mgnt_MAC          = ($conn | Get-HPEiLOIPv4NetworkSetting).PermanentMACAddress.ToLower();
                
                PowerSupply       = ($conn | Get-PowerSupplyData); 
                
                Health_Summary    = ($conn | Get-HealthSummaryData); 
                Processor         = ($conn | Get-ProcessorData);
                
                Memory            = ($conn | Get-MemoryData);
                NetworkInterfaces = ($conn | Get-NICData); 
                NetworkAdapter    = ($conn | Get-NetAdapterData); 
                Devices           = ($conn | Get-DeviceData); 
                Storage           = ($conn | Get-StorageData); 
                
                IPv4Configuration = ($conn | Get-IPv4Data); 
                IPv6Configuration = ($conn | Get-IPv6Data); 
            }
            Log 6 "$srv querrying finished." -IgnoreLogActive
            $report += $srvReport;

            $i++;
        }
        # Log Result to Terminal
        Log 3 "Querying ILO finished..."
        return $report;

    }
    catch {
        $message = $_.Exception.Message.ToString();
        if ($message -match "401") {
            Save-Exception $_ "The ILO-Server $srv returned Unauthorized. Verify that the password in your login.json is correct and you are able to log into the ILO-Interface with it.";
        }
        elseif ($message -match "SSL") {
            Save-Exception $_ "The ILO-Server $srv returned an Error with SSL. Verify that your certificate is properly set or set the flag '-DeactivateCertificateValidationILO'.";    
        }
        else {
            Save-Exception $_ ($_.Exception.Message.ToString());

        }
    }
}

Function Register-Directory {
    <#
    .DESCRIPTION
    Checks the Path that is passed in if it exists and if a file is passed in, it will split the path so that only the Directory is the path
    #>
    param(
        # Path that will be checked if its a directory
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Toggle if the Directory should be generated if it does not exist
        [Parameter()]
        [switch]
        $IgnoreError

    )
    try {
        Log 5 "Check if Directory '$path' exists and create it if needed."
        if ((-not (Test-Path -Path $Path)) -and $IgnoreError) {
            New-Item -Path $Path -Force -ItemType Directory | Out-Null;
            return $Path.ToString();
        }
        elseif (Test-Path -Path $path) {  
            Log 6 "`tPath $path already exists, now splitting it to return only the directory." 
            $isDirectory = (Get-Item ($Path)).Extension.Length -eq 0;
            if (-not $isDirectory) {
                $Path = $Path | Split-Path -Parent -Resolve;
            }
            return $Path.ToString();
        }
        else {
            throw [System.IO.DirectoryNotFoundException] "The directory at '$Path' does not exist. Please verify that the specified path and all its parent folders exist."
        }
        
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Save-DataInJSON {
    param(
        # Report that'll be saved to a report.json
        [Parameter(Mandatory = $true)]
        [Psobject]
        $Report
    )
    try {
        Log 4 "Begin saving results in JSON";
        # Guarantee that a Directory exists at reportPath
        $config = Get-Config;
        $path = Register-Directory ($config.reportPath)
        Update-Config -ReportPath $path;
        # Save to File with current Date as name
        if (Test-Path -Path ($path)) {
            [string]$date = (Get-Date -Format $DATE_FILENAME).ToString();
            $name = "$path\ilo_report_$date.json";
            Log 6 "`tSave result at $name";
            $report | ConvertTo-Json -Depth 15 | Out-File -FilePath $name -Force;
            return $name;
        }
        else {
            throw [System.IO.DirectoryNotFoundException] "No appropriate path could be find to save the report files. Please verify the specified one exists. The current path is '$path'"
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.ToString());
    }
}

Function Save-DataInCSV {
    param(
        # Report from which the csv-Files will be generated
        [Parameter(Mandatory = $true)]
        [Psobject]
        $Report    
    )

    try {
        # Guarantee that a Directory exists at reportPath
        Log 4 "Begin saving results in CSV"
        $config = Get-Config;
        $pathToReportTo = (Register-Directory ($config.reportPath)).ToString(); 
        Update-Config -ReportPath $pathToReportTo;
         
        $config = Get-Config;
        $path = $config.reportPath;
    
        if (Test-Path -Path $path) {
            # Save General.csv (like in Inventory)
            Save-GeneralInformationToCSV -Report $Report;
        
            # Save MAC.csv (if not deactivated)
            if (-not $config.ignoreMACAddress) {
                Save-MACInformationToCSV -Report $Report;
            }

            # Save SerialNumber.csv (if not deactivated) -- long because it must be mapped as simple as possible from a very nested structure
            if (-not $config.ignoreSerialNumbers) {
                Save-SerialInformationToCSV -Report $Report;
            }
            return $path;
        }
        else {
            throw [System.IO.DirectoryNotFoundException] "No appropriate path could be find to save the report files. Please verify the specified one exists. The current path is '$path'"
        }
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Get-StandardizedCSV {
    param(
        # Object, in which all Members will be standardized to exist.
        [Parameter(Mandatory = $true)]
        $Report
    )
    try {
        # Guarantee that all Keys used in the entire array of objects exist on all - otherwise csv has a problem with displaying all of them
        Log 5 "Standardizing Keys across array of object passed in."
        $unique = $Report | ForEach-Object { $_.Keys } | Select-Object -Unique
        foreach ($srvObj in $Report) {
            foreach ($uniqueMember in $unique) {
                if (($srvObj.Keys -contains $uniqueMember) -eq $false) {    
                    $srvObj | Add-Member -Name $uniqueMember -Value $NO_VALUE_FOUND_SYMBOL -MemberType NoteProperty;
                }
            }
        }
        return $Report;
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
}

Function Get-InventoryData {
    try {
        # Return Inventorydata from previously saved file.
        $config = Get-Config;
        $path = $config.searchForFilesAt + "\inventory_results.json";
        Log 5 "Import Inventory Data from '$path'"
        if (Test-Path -Path $path) {
            $server = Get-Content $path | ConvertFrom-Json -Depth 10;
        }else{
            throw [System.IO.FileNotFoundException] "No Inventory file has been found at'$path'.";
        }
    }
    catch [System.IO.FileNotFoundException], [System.IO.DirectoryNotFoundException] {
        Save-Exception $_ "The file $path does not exist or has been moved. Do not move or delete, as it is vital to query from Inventory.";
        return {};
    }
    catch {
        Save-Exception $_ ($_.Exception.Message.ToString());
    }
    return $server;
}