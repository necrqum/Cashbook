@echo off
setlocal enabledelayedexpansion

title [CB_Observe]

:: Farbcodes für Textausgaben
set "color_reset=[0m"
set "color_info=[32m"
set "color_warning=[33m"
set "color_error=[31m"
set "color_status=[36m"
set "color_info_highlight=[42;37m"
set "color_warning_highlight=[43;37m"
set "color_error_highlight=[41;37m"
set "color_status_highlight=[46;37m"

:: Not finito yet

:: Allgemeine Fehlerbehandlungsfunktion
:handle_error
    set "process_name=%~1"  :: Parameter 1: Prozessname oder Beschreibung
    set "error_code=!errorlevel!"  :: Nutze den errorlevel direkt hier

    :: Überprüfung des Errorlevels
    if !error_code! neq 0 (
        echo "%color_error%[ERROR] Fehler beim Prozess "!process_name!". Fehlercode: !error_code!%color_reset%"
        
        :: Erweiterte Fehlermeldungen basierend auf dem Errorlevel
        if !error_code! == 1 (
            echo "%color_error%[ERROR] Allgemeiner Fehler (Falscher Befehl oder ungültige Operation).%color_reset%"
            timeout /t 3 > nul
        ) else if !error_code! == 2 (
            echo "%color_error%[ERROR] Datei oder Verzeichnis nicht gefunden. Überprüfen Sie den Pfad: "!process_name!".%color_reset%"
            timeout /t 3 > nul
        ) else if !error_code! == 3 (
            echo "%color_error%[ERROR] Pfad wurde nicht gefunden. Möglicherweise ist der angegebene Pfad ungültig: "!process_name!".%color_reset%"
            timeout /t 3 > nul
        ) else if !error_code! == 5 (
            echo "%color_error%[ERROR] Zugriff verweigert. Überprüfen Sie die Berechtigungen für: "!process_name!".%color_reset%"
            timeout /t 3 > nul
        ) else if !error_code! == 87 (
            echo "%color_error%[ERROR] Ungültiger Parameter. Überprüfen Sie die Syntax des Befehls: "!process_name!".%color_reset%"
            timeout /t 3 > nul
        ) else (
            echo "%color_error%[ERROR] Unbekannter Fehler aufgetreten. Fehlercode: !error_code! für: "!process_name!".%color_reset%"
            timeout /t 3 > nul
        )
    ) else (
        echo %color_status%[STATUS] Der Prozess "!process_name!" wurde erfolgreich abgeschlossen.%color_reset%
        timeout /t 3 > nul
    )
    exit /b "!error_code!"