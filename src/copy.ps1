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
        "/PROGRESS"    # Zeigt Fortschrittsbalken
    )

    switch ($OverwriteMode) {
        "Always" { $robocopyParams += "/IS" }
        "Never" { $robocopyParams += "/XC /XN /XO" }
        "IfNewer" { $robocopyParams += "/XO" }
    }

    # Führe Robocopy aus
    $result = Start-Process robocopy -ArgumentList $robocopyParams -NoNewWindow -Wait -PassThru

    # Überprüfe Robocopy Exit Code
    switch ($result.ExitCode) {
        0 { Write-Host "Erfolg: Keine Dateien wurden kopiert." }
        1 { Write-Host "Erfolg: Dateien wurden erfolgreich kopiert." }
        2 { Write-Host "Erfolg: Zusätzliche Dateien oder Ordner wurden ignoriert." }
        4 { Write-Host "Warnung: Einige Fehler während des Kopiervorgangs." }
        8 { throw "Fehler: Einige Dateien oder Ordner konnten nicht kopiert werden." }
        16 { throw "Schwerwiegender Fehler beim Kopieren." }
        default { throw "Unbekannter Fehler: $($result.ExitCode)" }
    }

    exit $result.ExitCode
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}