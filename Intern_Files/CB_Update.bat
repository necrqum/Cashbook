@echo off
setlocal enabledelayedexpansion

:: reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f :: für win 10+

title [CB_Updater]

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

echo. >"%TEMP%\CB\shutdown.flag"
call :handle_error "Datei erstellt"
title CB_Update

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
set /p version=<"%Storage%\CB\System\Files\Temp\version.txt"
if errorlevel 1 (
    call :handle_error "Fehler beim Lesen der Version"
    exit /b 1
)

:: Die Version herunterladen & lesen
curl -o "%Storage%\CB\System\Tools\Temp\version.txt" "https://raw.githubusercontent.com/necrqum/cashbook/main/Intern_Files/version.txt"
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
    call :handle_error "Datei löschen"

    :: shutdown-flag2 erstellen
    echo. > "%TEMP%\CB\shutdown2.flag"
    call :handle_error "Datei erstellen" 

    cls
    echo %color_info%[INFO] Sie verwenden bereits die aktuellste Version [%color_info_highlight%V%version%%color_reset%%color_info%]!%color_reset%
    timeout /t 5 /nobreak > nul
    exit
) else goto :update_available


:update_available
echo %color_info%[INFO] A new update is available [%color_info_highlight%V%t_version%%color_reset%%color_info%]!%color_reset%
echo.
echo Wollen Sie die neue Version herunterladen? 
echo "(ja/nein) oder (1/2)"
set /p cho="> "

if /i "%cho%"=="j" goto :update
if /i "%cho%"=="n" goto :skip_update
if /i "%cho%"=="1" goto :update
if /i "%cho%"=="2" goto :skip_update

echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
timeout /t 3
goto :update_available

:update
:: shutdown-flag löschen
del "%TEMP%\CB\shutdown.flag"
call :handle_error "Datei löschen"

cls
echo %color_info%[INFO] Update wird durchgeführt.%color_reset%
echo %color_warning%[WARNING] Programm nicht beenden.%color_reset%
timeout /t 3 /nobreak > nul

:: Vorhandene Datei löschen, bevor die neue heruntergeladen wird
del "%cb_path%CB.bat"
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
echo %color_info%[INFO] CB.bat wurde auf Version [%color_info_highlight%V%version%%color_reset%%color_info%] aktualisiert.%color_reset%
timeout /t 2 /nobreak

:: CB.bat starten
cd /d "%cb_path%" && start CB.bat
timeout /t 3
exit

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