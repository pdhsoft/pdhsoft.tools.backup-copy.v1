[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,

    [Parameter()]
    [ValidateSet("Always", "Never", "IfNewer")]
    [string]$OverwriteMode = "IfNewer"
)

try {
    # Prüfe ob Robocopy verfügbar ist
    if (-not (Get-Command "robocopy.exe" -ErrorAction SilentlyContinue)) {
        throw "Robocopy ist nicht verfügbar. Robocopy ist Teil des Windows Resource Kit und sollte standardmäßig installiert sein."
    }

    # Überprüfe ob Quell- und Zielverzeichnis existieren
    if (-not (Test-Path $SourcePath)) {
        throw "Quellverzeichnis existiert nicht: $SourcePath"
    }

    # Erstelle Zielverzeichnis falls nicht vorhanden
    if (-not (Test-Path $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath | Out-Null
    }

    # Setze Robocopy Parameter basierend auf OverwriteMode
    $robocopyParams = @(
        $SourcePath
        $DestinationPath
        "/E"           # Kopiert Unterverzeichnisse, auch leere
        "/Z"           # Kopiert im Wiederaufnahmemodus
        "/MT:8"        # Multithreading für bessere Performance
        "/COPY:DT"     # Kopiert nur Daten und Timestamps (keine Attribute)
        "/TEE"         # Zeigt Fehler im Konsolenfenster
        "/bytes"       # Zeigt Bytes statt Prozent
        "/XD"          # Verzeichnisse ausschließen
        "`$Recycle.Bin"  # Windows Papierkorb (neuere Systeme)
        "RECYCLER"     # Windows Papierkorb (ältere Systeme)
        "System Volume Information"  # System-Verzeichnis
    )

    switch ($OverwriteMode) {
        "Always" { $robocopyParams += "/IS" }
        "Never" { $robocopyParams += "/XC /XN /XO" }
        "IfNewer" { $robocopyParams += "/XO" }
    }

    # Temporärer Log-Pfad
    $logFile = Join-Path $env:TEMP "robocopy_progress.log"

    # Robocopy ausführen
    $process = Start-Process robocopy -ArgumentList $robocopyParams -NoNewWindow -PassThru -RedirectStandardOutput $logFile

    # Fortschrittsanzeige
    while (!$process.HasExited) {
        if (Test-Path $logFile) {
            $currentOperation = (Get-Content $logFile -Tail 1) -join " "
            if (-not [string]::IsNullOrWhiteSpace($currentOperation)) {
                Write-Progress -Activity "Kopiere Dateien" -Status ($currentOperation.ToString())
            }
            else {
                Write-Progress -Activity "Kopiere Dateien" -Status "Warte auf Robocopy..."
            }
        }
        Start-Sleep -Milliseconds 100
    }

    # Aufräumen
    Remove-Item $logFile -ErrorAction SilentlyContinue

    # Überprüfe Robocopy Exit Code
    switch ($process.ExitCode) {
        0 { Write-Host "Erfolg: Keine Dateien wurden kopiert." }
        1 { Write-Host "Erfolg: Dateien wurden erfolgreich kopiert." }
        2 { Write-Host "Erfolg: Zusätzliche Dateien oder Ordner wurden ignoriert." }
        4 { Write-Host "Warnung: Einige Fehler während des Kopiervorgangs." }
        8 { throw "Fehler: Einige Dateien oder Ordner konnten nicht kopiert werden." }
        16 { throw "Schwerwiegender Fehler beim Kopieren." }
        default { throw "Unbekannter Fehler: $($process.ExitCode)" }
    }

    exit $process.ExitCode
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}