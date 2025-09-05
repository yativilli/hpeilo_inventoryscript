# Inventory Script to query ILO-Servers from a central database and get info from those queried servers

# Overview

ILO-Inventariuer is a PowerShell module that can be used to query servers from an API of a central database and save them locally. Based on these servers, with the help of HP-ILO technology, those servers are querried to get their parts MAC-Addresses and serialnumbers.   

This project was created as an Individuelle Praktische Arbeit (**IPA** - final exam of apprenticeship) by Yannick Wernle during a ten day timespan and with its most aggregious errors fixed in the days and weeks after. There will (almost certainly still be some errors I've not yet fixed).   

## Usage

### General
This module offers functionality that goes beyond simply querying hardware information from HPE ILO machines. It is designed for the Paul Scherrer Institute (PSI) and queries the internal database ‘inventory.psi.ch’. Its functions are managed via generated config.json files.   

There are a few important functions you should be aware of:   
- `Get-HWInfoFromILO` Main function that performs the actual query for ILO and inventory. Use this function to make the script do something (create configuration, start query, etc.).   
- `Get-ServerByScanner` Main Function that can be used with a USB-Scanner to record servers that are not yet in the internal database.   
- `Set-ConfigPath` Sets the path to the config file to a different location   
- `Get-ConfigPath` Determines the path to the current config file   
- `Get-Config` Returns the current config with all values as a PowerShell object   
- `Update-Config` Updates the current config (use parameters)   
- `Get-NewConfig` Resets the current configuration and displays the screen for creating a new configuration   

Since not everyone who uses this script is familiar with how to call up help in PowerShell, you can get help using the following syntax (the output is always the same):   
```   
Get-Help Get-HWInfoFromILO   
Set-ConfigPath /?   
Get-ConfigPath -h   
Get-Config --help   
```   

### Get-HWInfoFromILO
To Start the Programm simply import the module and its dependencies and then run Get-HWInfoFromILO.   
```   
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;   
Import-Module HPEiLOCmdlets;   

Get-HWInfoFromILO   
```   
This will result three options:    
1. Generate an empty config at a specified path   
2. Generate a config with example data   
3. add path to an existing config   

**NOTE**
When choosing 1. or 2., the configuration MUST BE EDITED before the script will run without errors:   
- Update config.json with the configuration you want   
- Update login.json with the Username(s) and Password(s) set for the servers to be querried (if only one is specified, it will used be for all).   

### Get-ServerByScanner

### Configuration Options
- `searchForFilesAt`: Path used for searching for files if no path is specified and where files are safed if no path is specified.   
- `configPath`: Path to the configuration file that is used (so the path to itself).    
- `loginConfigPath`:Path to the login.json: Must be a path to a file or a path containing a `login.json`. The specified json must contain at least one element with the elements `Username` and `Password`.   
- `reportPath`: Path where the output-files (CSV and JSON will be saved to).   
- `serverPath`: If the database shall not be querried, this must point to an array of the remote-access names of the ILO ports: `[rmdl123test.psi.ch,rmdl456.psi.ch]`.    
- `logPath`: Path where the logs will be saved to.   
- `logLevel`: Loglevel from 0 to 6: 0 logs nothing, 6 very much.   
- `loggingActivated`: Activates/Deactivates Logging.   
- `searchStringInventory`: String that will be used for querrying the database `rm-` will match for all servers starting with rm- etc.   
- `doNotSearchInventory`: Deactivates database search: This must be activated if you want to use the file at `serverPath`.   
- `deactivateCertificateValidation`: Deactivates Validation of Certificate when logging into the remote management interface of ILO.   
- `logToConsole`:Logs will be logged in PS-Console.   
- `ignoreMACAddress`: Won't log MAC-Addresses to file.   
- `ignoreSerialNumbers`: Won't log Serial Numbers to file.   

### InstallLatestVersion.ps1
This script is a standalone and automatically downloads the newest published release and imports that module.   
- `.\InstallLatestVersion.ps1 -Update`   


## Requirements
- [PowerShell 7.5 or up](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)   
- [HPEiLOCmdlets 4.0.0.0](https://www.powershellgallery.com/packages/HPEiLOCmdlets/4.4.0.0)   

Servers tested under the current version v.1.1.0:   
- HP ProLiant DL380 Gen 8   
- HP ProLiant DL380 Gen 9   
- HP ProLiant DL380 Gen 10   
- HP ProLiant DL380 Gen 11   
- HP ProLiant DL20 Gen 10   

Note that due to the different ILO-Version of these servers, some parts of the querry won't be able to turn out some of the info, due to the functionality not existing in those versions.   

## Tests

There are some End2End, Unit Tests and other tests that tests the functions of the individual functions and configurations that can be made. Those were made using the Pester Framework.   

For them to be run, you must have installed [Pester](https://pester.dev/).   
They can be run by using:   
`Invoke-Pester -Output 'Detailed' -Path 'pathtotests'`   