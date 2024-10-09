@echo off
setlocal enabledelayedexpansion

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

:: Variablen definieren
set "file=%TEMP%\CB\path.txt"

:: Überprüfe, ob die Datei existiert
if not exist "%file%" (
    call :handle_error "Datei '%file%' nicht gefunden"
    exit /b 1
)

set "count=0"

:: Datei Zeile für Zeile lesen
for /f "tokens=*" %%i in ('type "%file%"') do (
    set /a count+=1
    if !count! equ 1 set "cb_path=%%i"
    if !count! equ 2 set "Storage=%%i"
    if !count! gtr 2 goto :break_loop
)
:break_loop

:: Sicherstellen, dass die Pfade gesetzt wurden
if not defined cb_path (
    call :handle_error "cb_path konnte nicht aus der Datei gelesen werden"
    exit /b 1
)

if not defined Storage (
    call :handle_error "Storage konnte nicht aus der Datei gelesen werden"
    exit /b 1
)

:: Version aus Datei lesen
set /p version=<"%Storage%\CB\Files\Temp\version.txt"
if errorlevel 1 (
    call :handle_error "Fehler beim Lesen der Version"
    exit /b 1
)

:: Die Version herunterladen & lesen
curl -o "%Storage%\CB\System\Tools\Temp\version.txt" "https://raw.githubusercontent.com/necrqum/cashbook/main/Intern_Files/version.txt" -v -i
if errorlevel 1 (
    call :handle_error "Fehler beim Herunterladen der neuen Version"
    exit /b 1
)

set /p t_version=<"%Storage%\CB\System\Tools\Temp\version.txt"
if errorlevel 1 (
    call :handle_error "Fehler beim Lesen der heruntergeladenen Version"
    exit /b 1
)

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
del "%cb_path%\CB.bat"
call :handle_error "Datei löschen"

:: Datei verschieben
move /y "%Storage%\CB\System\Tools\Temp\version.txt" "%Storage%\CB\System\Files\Temp\version.txt"
call :handle_error "Datei verschieben"

:: Die neue CB.bat herunterladen
curl -o "%cb_path%\CB.bat" "https://raw.githubusercontent.com/necrqum/cashbook/main/CB.bat"
call :handle_error "Datei herunterladen"

:: Erfolgsmeldung
cls
echo %color_info%[INFO] Alle Schritte erfolgreich abgeschlossen!%color_reset%
timeout /t 2 /nobreak

:: CB.bat starten
cd %cb_path% && start CB.bat
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