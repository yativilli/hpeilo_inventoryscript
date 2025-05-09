# Inventurscript zum Abgleich von installierter Hardware mit einer zentralen Datenbank

## Überblick

ILO-Inventarizer ist ein PowerShell-Modul, welches dazu verwendet werden kann, eine interne Daten der am PSI benützten Kameraserver per ILO abzufragen.
Neben der Abfrage von ILO (Integrated Lights Out) gibt es auch die Möglichkeit, die PSI-interne Datenbank Inventory.psi.ch abzufragen, anstatt die Server einzeln anzugeben.

## Anwendung

Dieses Modul bietet die Funktionalität, nicht nur Hardware-Informationen von HPE-ILO Maschinen abzufragen. Es ist für das Paul Scherrer Institut (PSI) konzipiert und fragt
aus der internen Datenbank 'inventory.psi.ch' ab. Seine Funktionen werden über generierte config.json-Dateien verwaltet.

Es gibt ein paar wichtige Funktionen, die Sie kennen sollten:

- `Get-HWInfoFromILO` Hauptfunktion, die die eigentliche Abfrage für ILO und Inventory übernimmt. Um das Skript dazu zu bringen, etwas zu tun (Konfiguration erstellen, Abfrage starten usw.) verwenden Sie diese Funktion.
- `Set-ConfigPath` Setzt den Pfad zur Config-Datei auf einen anderen Ort
- `Get-ConfigPath `Ermittelt den Pfad zur aktuellen Config-Datei
- `Get-Config` Gibt die aktuelle Config mit allen Werten als PowerShell-Objekt zurück
- `Update-Config` Aktualisiert die aktuelle Config (Parameter verwenden)
- `Get-NewConfig` Setzt die aktuelle Config zurück und zeigt den Bildschirm zum Erstellen einer neuen Config an

Starten Sie den Teil des Skripts mit:
`Get-HWInfoFromILO`

Da nicht jeder, der dieses Skript verwendet, mit der Art und Weise vertraut ist, wie die Hilfe in PowerShell aufgerufen wird, können Sie die Hilfe mit der folgenden Syntax abrufen (die Ausgabe ist immer die gleiche):
```
Get-Help Get-HWInfoFromILO
Set-ConfigPath /?`
Get-ConfigPath -h
Get-Config --help
```
Sie finden den Sourcecode hier: https://github.com/yativilli/hpeilo_inventoryscript

Dieses Projekt wurde als Individuelle Praktische Arbeit von Yannick Wernle innerhalb von 10 Tagen entwickelt, daher kann es einige Fehler geben, die nicht behoben sind.
© Yannick Wernle, Paul Scherrer Institut (PSI) 2025

## Voraussetzungen

Um das Modul korrekt zu verwenden muss die Bibliothek [HPEiLOCmdlets](https://www.powershellgallery.com/packages/HPEiLOCmdlets/4.4.0.0) installiert sein.
Ausserdem muss PowerShell von mindestens Version 7.0.0 verwendet werden.

## Anwendung Manuell starten
Starten sie das Programm entweder manuell so:

```
Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1;
Import-Module HPEiLOCmdlets;

Get-HWInfoFromILO
```

oder führen Sie `.\src\script.ps1` aus.

## Start m