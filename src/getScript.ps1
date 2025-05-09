param(
    [switch]
    $Update
)
if ($Update) {
    Remove-Module ILO-Inventorizer -Force;
    $latestSourceCodePath = "https://api.github.com/repos/yativilli/hpeilo_inventoryscript/releases/latest"
    $sourceCodeZip = (Invoke-RestMethod -Method Get $latestSourceCodePath).zipball_url
    $saveFolder = ($ENV:TEMP + "\ilo_inv_installer");
    if ((Test-Path $saveFolder) -eq $false) {
        New-Item -ItemType Directory $saveFolder
    }
    $zipPath = $saveFolder + "\hpeilo_script.zip"
    Invoke-WebRequest $sourceCodeZip -OutFile $zipPath;

    # Expand-Archive -Path $zipPath -DestinationPath $saveFolder -Force;
    $nameOfFolder = ((Get-ChildItem -Path $saveFolder -Force ) | Where-Object { $_.Name -match "yativilli-hpeilo" }).Name
    $pathToModule =  "$saveFolder\$nameOfFolder\src\ILO-Inventorizer\ILO-Inventorizer.psm1";
    $ENV:PATH_ILOINV_MODULE = $pathToModule
}
$ENV:PATH_ILOINV_MODULE
$pathToModule = $ENV:PATH_ILOINV_MODULE;
Import-Module $pathToModule;