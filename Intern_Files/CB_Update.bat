@echo off
setlocal enabledelayedexpansion

:: Den Pfad aus der Datei lesen
set /p path=<"%TEMP%\CB\path.txt"

:: Die Abhängigkeiten aufrufen
call "%path%\CB.bat" :abhängigkeiten

:: Die Version herunterladen & lesen
curl -o "%Storage%\CB\System\Tools\Temp\version.txt" "https://raw.githubusercontent.com/necrqum/cashbook/main/Intern_Files/version.txt"
set /p t_version=<"%Storage%\CB\System\Tools\Temp\version.txt"

:: Überprüfen, ob ein Update verfügbar ist
if "%version%"=="%t_version%" (
    del "%Storage%\CB\System\Tools\Temp\version.txt"
    exit /b 0
) else (
    :update_available
    echo %color_info%[INFO] A new update is available {%color_info_highlight%%t_version%%color_info%}!%color_reset%
    echo.
    echo Wollen Sie die neue Version herunterladen?
    echo (Ja/Nein) / (1/2)
    set /p cho="> "
    
    if /i "%cho%"=="j" goto :update
    if /i "%cho%"=="n" goto :skip_update
    if /i "%cho%"=="1" goto :update
    if /i "%cho%"=="2" goto :skip_update
    
    echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
    timeout /t 3
    goto :update_available
)

:update
:: Vorhandene Datei löschen, bevor die neue heruntergeladen wird
del "%path%\CB.bat"
call :handle_error "Datei löschen"

:: Datei verschieben
move /y "%Storage%\CB\System\Tools\Temp\version.txt" "%Storage%\CB\System\Files\Temp\version.txt"
call :handle_error "Datei verschieben"

:: Die neue CB.bat herunterladen
curl -o "%path%\CB.bat" "https://raw.githubusercontent.com/necrqum/cashbook/main/CB.bat"
call :handle_error "Datei herunterladen"

:: Erfolgsmeldung
cls
echo %color_info%[INFO] Alle Schritte erfolgreich abgeschlossen!%color_reset%
timeout /t 2 /nobreak

:: CB.bat starten
start "" "%path%\CB.bat"
timeout /t 3
exit /b 0

:: Allgemeine Fehlerbehandlungsfunktion
:handle_error
    set "process_name=%~1"  :: Parameter 1: Prozessname oder Beschreibung
    set "error_code=!errorlevel!"  :: Nutze den errorlevel direkt hier

    :: Überprüfung des Errorlevels
    if !error_code! neq 0 (
        echo %color_error%[ERROR] Fehler beim Prozess "!process_name!". Fehlercode: !error_code!%color_reset%
        
        :: Erweiterte Fehlermeldungen basierend auf dem Errorlevel
        if !error_code! == 1 (
            echo %color_error%[ERROR] Allgemeiner Fehler (Falscher Befehl oder ungültige Operation).%color_reset%
        ) else if !error_code! == 2 (
            echo %color_error%[ERROR] Datei oder Verzeichnis nicht gefunden. Überprüfen Sie den Pfad: "!process_name!".%color_reset%
        ) else if !error_code! == 3 (
            echo %color_error%[ERROR] Pfad wurde nicht gefunden. Möglicherweise ist der angegebene Pfad ungültig: "!process_name!".%color_reset%
        ) else if !error_code! == 5 (
            echo %color_error%[ERROR] Zugriff verweigert. Überprüfen Sie die Berechtigungen für: "!process_name!".%color_reset%
        ) else if !error_code! == 87 (
            echo %color_error%[ERROR] Ungültiger Parameter. Überprüfen Sie die Syntax des Befehls: "!process_name!".%color_reset%
        ) else (
            echo %color_error%[ERROR] Unbekannter Fehler aufgetreten. Fehlercode: !error_code! für: "!process_name!".%color_reset%
        )
    ) else (
        echo %color_info%[INFO] Der Prozess "!process_name!" wurde erfolgreich abgeschlossen.%color_reset%
    )
    exit /b !error_code!