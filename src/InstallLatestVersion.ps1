param(
    [switch]
    $Update,

    [switch]
    $InstallHPEILO
)
try {

    if ($Update) {
        # Remove Current Module
        if ((Get-Module -Name ILO-Inventorizer).Count -gt 0) {
            Write-Host "Module is currently loaded. Unloading it first..." -ForegroundColor Yellow;
            Remove-Module ILO-Inventorizer -Force;
        }

        # Get newest version from GitHub
        $latestSourceCodePath = "https://api.github.com/repos/yativilli/hpeilo_inventoryscript/releases/latest"
        $sourceCodeZip = (Invoke-RestMethod -Method Get $latestSourceCodePath).zipball_url
        $saveFolder = ($ENV:TEMP + "\ilo_inv_installer");
        if ((Test-Path $saveFolder) -eq $false) {
            New-Item -ItemType Directory $saveFolder
        }
        $zipPath = $saveFolder + "\hpeilo_script.zip"
        Invoke-WebRequest $sourceCodeZip -OutFile $zipPath;
    
        # Expand to modules folder
        Expand-Archive -Path $zipPath -DestinationPath $saveFolder -Force;
        $nameOfFolder = ((Get-ChildItem -Path $saveFolder -Force ) | Where-Object { $_.Name -match "yativilli-hpeilo" }).Name
        
        $pathToModule = "$saveFolder\$nameOfFolder" + "\src\ILO-Inventorizer";
        Write-Host "EXPANDED: $pathToModule" -ForegroundColor Green;
        
        # Copy to Modules folder
        $psModulePath = $ENV:PSModulePath.Split(";") | Select-Object -First 1;
        Copy-Item -Path $pathToModule -Destination $psModulePath -Recurse -Force;
        Import-Module ILO-Inventorizer;
        $inventorizerModule = (Get-Module -Name ILO-Inventorizer).Version.ToString();
        Write-Host "'ILO-Inventorizer'-Module updated to the latest version: $inventorizerModule" -ForegroundColor Green;

        # Import HPEiLO Module
        if($InstallHPEILO){
            Install-Module -Name HPEiLOCmdlets -RequiredVersion 4.0.0.0 -Force -AcceptLicense
            $hpeilomodule = (Get-Module -Name HPEiLOCmdlets).Version.ToString();

            Write-Host "'HPEiLOCmdlets'-Module installed to the version: $hpeilomodule" -ForegroundColor Green;
        }
    } else{
        Import-Module ILO-Inventorizer;
        Import-Module HPEiLOCmdlets;
    }
}
catch {
    Write-Host "Error in updating the module: $_"
}