@echo off
setlocal enabledelayedexpansion

:: Abhängigkeiten
call :abhängigkeiten

:: setup
title Kassenbuch [V%version%].bat
call :log_function ":process_requirements" 1
call :log_function ":counter" 1

if "%info%" == "1" (
    cls
    echo Welcome %username%!
    echo.
    echo Please consider to read our guidelines.
    start https://github.com/necrqum/Cashbook/README.md
    timeout /t 15
)

:: Hauptmenü
:main_menu
cls
echo Willkommen %username%!
echo.
echo (1) Neuen Eintrag vornehmen.
echo (2) Alten Eintrag einsehen.
echo (3) Einstellungen.
echo (4) Programm Schliessen.
echo.
set /p cho="> "
if /i "%cho%"=="1" goto new_entry
if /i "%cho%"=="2" goto old_entry
if /i "%cho%"=="3" goto settings
if /i "%cho%"=="4" (
    REM Platz für Log-Eintrag
    exit
)
echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
timeout /t 3
goto :main_menu

:: Funktion für Abhängigkeiten
:abhängigkeiten
    if exist "settings.txt" (
        set /p Storage=<settings.txt
    ) else (
        set Storage="%userprofile%\Desktop"
    )
    set /p version=<"%Storage%\CB\System\Files\Temp\version.txt"

    :: Farbcodes für Textausgabe
    set "color_reset=[0m"
    set "color_info=[32m"
    set "color_warning=[33m"
    set "color_error=[31m"
    set "color_status=[36m"
    set "color_info_highlight=[42;37m"
    set "color_warning_highlight=[43;37m"
    set "color_error_highlight=[41;37m"
    set "color_status_highlight=[46;37m"
    goto :eof

:: Funktion zum Verarbeiten der requirements.txt
:process_requirements
    set "file=%TEMP%\CB\requirements.txt"

    :: Überprüfen, ob die Datei existiert
    if not exist "%file%" (
        echo %color_error%[ERROR] Die Datei "%file%" wurde nicht gefunden!%color_reset%
        mkdir "%TEMP%\CB"
        echo %~p0>"%TEMP%\CB\path.txt"
        echo %color_status%[STATUS] Lade requirements.txt herunter.%color_reset%
        curl -o "%TEMP%\CB\requirements.txt" https://raw.githubusercontent.com/necrqum/Cashbook/main/requirements.txt
        if errorlevel 1 (
            echo %color_error%[ERROR] Fehler beim Herunterladen der requirements.txt.%color_reset%
            exit /b 1
        ) else (
            echo %color_info%[INFO] Die Datei %file% wurde erfolgreich heruntergeladen und gespeichert.%color_reset%
        )
    )

    :: Variablen für den aktuellen Modus und Zähler
    set "mode="
    set "env_counter=0"
    set "download_counter=0"

    :: Zeilenweise Verarbeitung der Datei
    for /f "usebackq tokens=*" %%A in ("%file%") do (
        set "line=%%A"

        :: Überprüfen auf Modus "-Umgebung" oder "-Download"
        if "!line!"=="-Umgebung-" (
            echo %color_info%[INFO] Modus "-Umgebung-" erkannt!%color_reset%
            set "mode=environment"
            set "env_counter=0"
        ) else if "!line!"=="-Download-" (
            echo %color_info%[INFO] Modus "-Download-" erkannt!%color_reset%
            set "mode=download"
            set "download_counter=0"
        ) else if defined mode (
            :: Verarbeitung der Umgebungszeilen (Verzeichniserstellung)
            if "!mode!"=="environment" (
                set /a env_counter+=1
                set "env_path!env_counter!=!line!"

                echo %color_status%[STATUS] Verzeichnispfad !env_counter!: %Storage%\!line!%color_reset%

                :: Überprüfen, ob das Verzeichnis existiert
                if not exist "!line!" (
                    echo %color_warning%[INFO] Verzeichnis existiert nicht. Erstelle: %Storage%\!line!%color_reset%
                    mkdir "%Storage%\!line!"
                    if errorlevel 1 (
                        echo %color_error%[ERROR] Fehler beim Erstellen des Verzeichnisses: %Storage%\!line!%color_reset%
                        exit /b 1
                    ) else (
                        echo %color_info%[INFO] Verzeichnis erfolgreich erstellt: %Storage%\!line!%color_reset%
                    )
                ) else (
                    echo %color_info%[INFO] Verzeichnis existiert bereits: %Storage%\!line!%color_reset%
                )
            )

            :: Verarbeitung der Downloadzeilen (Dateien herunterladen)
            if "!mode!"=="download" (
                set /a download_counter+=1
                
                :: Die erste Zeile nach "-Download" ist die URL
                if !download_counter! lss 2 (
                    set "download_url!download_counter!=!line!"
                    echo %color_status%[STATUS] Download-URL !download_counter!: !line!%color_reset%
                )

                :: Die zweite Zeile ist der Zielpfad
                if !download_counter! equ 2 (
                    set "download_path!download_counter!=!line!"
                    echo %color_status%[STATUS] Zielpfad für die Datei: %Storage%\!line!%color_reset%
                    
                    :: Extrahiere Dateiname aus URL
                    for %%B in ("!download_url1!") do set "filename=%%~nxB"
                    
                    :: Vollständiger Pfad zur Zieldatei
                    set "dest_file=%Storage%\!line!\!filename!"

                    :: Datei nur herunterladen, wenn sie nicht bereits existiert
                    if not exist "!dest_file!" (
                        echo %color_info%[INFO] Lade herunter: !download_url1! nach %Storage%\!dest_file!%color_reset%
                        curl -o "!dest_file!" "!download_url1!"
                        if errorlevel 1 (
                            echo %color_error%[ERROR] Fehler beim Herunterladen der Datei: !download_url1!%color_reset%
                            exit /b 1
                        ) else (
                            echo %color_info%[INFO] Datei erfolgreich heruntergeladen: !dest_file!%color_reset%
                        )
                    ) else (
                        echo %color_warning%[INFO] Datei existiert bereits: !dest_file!%color_reset%
                    )

                    :: Zähler für Download zurücksetzen
                    set "download_counter=0"
                )
            )
        )
    )
    echo %color_info%[INFO] Alle Schritte erfolgreich abgeschlossen!%color_reset%
    goto :eof

:: Funktion zum Verarbeiten des Updaters
:counter
    if exist "%Storage%\CB\System\Files\Temp\counted.txt" (
        set /p count=<"%Storage%\CB\System\Files\Temp\counted.txt"
        echo !count!
        if !count! GEQ 5 (
            REM xcopy /s /i "%userprofile%\Desktop\Kassenbuch" "F:\Backup\Kassenbuch_%DATE%"
            echo 0 >"%Storage%\CB\System\Files\Temp\counted.txt"
            start "%Storage%\CB\System\Tools\CB_Update.bat"
            exit /b 0
        ) else (
            set /a n_count=!count! + 1
            echo !n_count! >"%Storage%\CB\System\Files\Temp\counted.txt"
        )
    ) else (
        echo 0 >"%Storage%\CB\System\Files\Temp\counted.txt"
        set Info=1
    )
    goto :eof

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

:: Erstellen von Logfiles 
:log_function
    setlocal enabledelayedexpansion
    set "logfile=%Storage%\CB\System\Files\Temp\Logs\output.log"
    
    :: Parameter 1: Funktionsname oder Befehl, Parameter 2: Optional, ob nur Fehler protokolliert werden sollen (1 = nur Fehler, 0 = alle Ausgaben)
    set "function_name=%~1"
    set "only_errors=%~2"

    (
        echo -------------------------------------------------------
        echo [%date% %time%] Start der Funktion: !function_name!
        echo -------------------------------------------------------
        
        :: Dynamische Ausführung des Befehls oder der Funktion
        if "!only_errors!" == "1" (
            call !function_name! 2>>"%logfile%" >>nul
            if errorlevel 1 (
                echo [%date% %time%] Fehler bei der Funktion: !function_name! >> "%logfile%"
            )
        ) else (
            call !function_name! >> "%logfile%" 2>&1
        )

        echo -------------------------------------------------------
        echo [%date% %time%] Ende der Funktion: !function_name!
        echo -------------------------------------------------------
    ) >> "%logfile%" 2>&1
    
    endlocal
    exit /b 0