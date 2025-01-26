# pdhsoft.tools.backup-copy.v1

Ein Tool zum Erstellen von Backups

## Beschreibung

Dieses PowerShell-Skript ermöglicht das automatisierte Backup von Verzeichnissen mit verschiedenen Überschreibungsoptionen.

## Verwendung

```powershell
.\copy.ps1 -SourcePath <Quellpfad> -DestinationPath <Zielpfad> -OverwriteMode <Always|Never|IfNewer>
```

### Parameter

- `SourcePath`: Pfad zum Quellverzeichnis (erforderlich)
- `DestinationPath`: Pfad zum Zielverzeichnis (erforderlich)
- `OverwriteMode`: Überschreibungsverhalten (optional, IfNewer ist Standart)
  - `Always`: Dateien immer überschreiben
  - `Never`: Vorhandene Dateien nie überschreiben
  - `IfNewer`: Nur überschreiben wenn Quelldatei neuer ist

### Beispiel

```powershell
.\copy.ps1 -SourcePath "C:\Daten" -DestinationPath "D:\Backup" -OverwriteMode "IfNewer"
```

## Aufgabenplanung

Das Skript kann über den Windows Task Scheduler automatisiert werden:

1. Task Scheduler öffnen
2. "Aufgabe erstellen..." wählen
3. Trigger nach Bedarf einrichten (z.B. täglich)
4. Als Aktion "Programm starten" wählen:
   - Programm: `powershell.exe`
   - Argumente: `-File "Pfad\zu\copy.ps1" -SourcePath "C:\Quelle" -DestinationPath "D:\Ziel" -OverwriteMode "IfNewer"`

## Features

- Robuste Dateiübertragung mit Wiederaufnahme-Modus
- Multithreading für bessere Performance
- Detaillierte Fehlerbehandlung
- Flexibles Überschreibungsverhalten
- Fortschrittsanzeige während der Ausführung
