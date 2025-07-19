@echo off
setlocal enabledelayedexpansion

:: Abhängigkeiten nur aufrufen, wenn der Parameter help übergeben wurde
if "%~1"=="-h" (
    echo help
    pause
) else if "%~1"=="--help" (
    echo help
    pause
)

:: Abhängigkeiten
call :abhängigkeiten
:: title Kassenbuch [V%version%].bat >> %logfile_outpud% 2>> %logfile_error%
title Kassenbuch [V%version%].bat

:: setup
call :process_requirements
call :counter

if "%info%" == "1" (
    cls
    echo Welcome %username%!
    echo.
    echo Please consider to read our guidelines.
    start https://github.com/necrqum/cashbook/blob/main/README.md
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
if /i "%cho%"=="1" goto :new_entry
if /i "%cho%"=="2" goto :old_entry
if /i "%cho%"=="3" goto :settings
if /i "%cho%"=="4" (
    REM Platz für Log-Eintrag
    exit
)
echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
timeout /t 3
goto :main_menu

:: Neuen Eintrag vornehmen
:new_entry
cls
echo Neuer Eintrag:
echo ---
set /p operation="Vorgang: "
set /p name="Name: "
set /p income="Einnahme: "
set /p expenditure="Ausgabe: "
echo.
:new_entry_question
cls
echo Neuer Eintrag:
echo ---
echo Ist dies so korrekt? (y/n)
echo Vorgang: %operation%
echo Name: %name%
echo Einnahme: %income%
echo Ausgabe: %expenditure%
echo.

:: Benutzer nach der Bestätigung fragen
set /p cho="Bitte geben Sie 'y' für ja oder 'n' für nein ein: "

if /i "%cho%"=="n" goto :main_menu
if /i "%cho%"=="y" goto :make_entry

echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
timeout /t 3
goto :new_entry_question

:: Funktion zur Behandlung des neuen Eintrags
:make_entry
call :get_date
:: Erstellen der Umgebung und Auslese der aktuellen Kassenbestände
if not exist "%Storage%\CB\Daten\%year%" (
        md "%Storage%\CB\Daten\%year%"
        if exist "%Storage%\CB\Daten\%year%\%CashBalanceFile%" (
            set /p CashBalance_year=<"%Storage%\CB\Daten\%year%\%CashBalanceFile%"
        ) else (
            set "CashBalance_year=0"
        )
    )
if not exist "%Storage%\CB\Daten\%year%\%month%" (
    md "%Storage%\CB\Daten\%year%\%month%"
    if exist "%Storage%\CB\Daten\%year%\%month%\%CashBalanceFile%" (
        set /p CashBalance_month=<"%Storage%\CB\Daten\%year%\%month%\%CashBalanceFile%"
    ) else (
        set "CashBalance_month=0"
    )
)
if not exist "%Storage%\CB\Daten\%year%\%month%\%day%" (
    md "%Storage%\CB\Daten\%year%\%month%\%day%"
    if exist "%Storage%\CB\Daten\%year%\%month%\%day%\%CashBalanceFile%" (
        set /p CashBalance_day=<"%Storage%\CB\Daten\%year%\%month%\%day%\%CashBalanceFile%"
    ) else (
        set "CashBalance_day=0"
    )
)
:: Aktualisieren der Kassenbestände
for /f %%i in ('powershell -command "%CashBalance_year% + %income% - %expenditure%"') do set CashBalance_year=%%i
echo %CashBalance_year%>"%Storage%\CB\Daten\%year%\%CashBalanceFile%"
for /f %%i in ('powershell -command "%CashBalance_month% + %income% - %expenditure%"') do set CashBalance_month=%%i
echo %CashBalance_month%>"%Storage%\CB\Daten\%year%\%month%\%CashBalanceFile%"
for /f %%i in ('powershell -command "%CashBalance_day% + %income% - %expenditure%"') do set CashBalance_day=%%i
echo %CashBalance_day%>"%Storage%\CB\Daten\%year%\%month%\%day%\%CashBalanceFile%"
:: Formatieren der Kassenbücher
set "cashbalance=%CashBalance_year%"
powershell -ExecutionPolicy Bypass -File "%Storage%\CB\System\Tools\CB_CreateExcel.ps1" "%operation%" "%name%" %income% %expenditure% "%Storage%\CB\Daten\%year%\Kassenbuch.xlsx" "%cashbalance%"
set "cashbalance=%CashBalance_month%"
powershell -ExecutionPolicy Bypass -File "%Storage%\CB\System\Tools\CB_CreateExcel.ps1" "%operation%" "%name%" %income% %expenditure% "%Storage%\CB\Daten\%year%\%month%\Kassenbuch.xlsx" "%cashbalance%"
set "cashbalance=%CashBalance_day%"
powershell -ExecutionPolicy Bypass -File "%Storage%\CB\System\Tools\CB_CreateExcel.ps1" "%operation%" "%name%" %income% %expenditure% "%Storage%\CB\Daten\%year%\%month%\%day%\Kassenbuch.xlsx" "%cashbalance%"
goto main_menu

:old_entry
echo old_entry
pause
goto main_menu

:settings
cls
echo Settings
echo.
echo (1) Speicher-Einstellungen.
echo (2) Update-Einstellungen.
echo (3) Sicherheits-Einstellungen.
echo (4) Startup-Einstellungen.
echo (5) Funktions-Einstellungen
echo (6) Zum Hauptmenü zurückkehren.
echo.
set /p cho="> "
if /i "%cho%"=="1" goto :storage_settings
if /i "%cho%"=="2" goto :update_settings REM z.B. Manuell updaten, update-counter einstellen, soll auch auf testversionen aktualisiert werden oder nur vollendete Versionen
if /i "%cho%"=="3" goto :safety_settings REM z.B. Verschlüsselung, Passwörter/Login
if /i "%cho%"=="4" goto :startup_settings REM z.B. autostart, verknüpfungen, reperatur-tool
if /i "%cho%"=="5" goto :function_settings
if /i "%cho%"=="6" goto :main_menu
echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
timeout /t 3
goto :setting

REM Verbesserung des Updaters, er soll neben dem Hauptprogramm auch alle tools aktualisieren können
REM Dafür muss auch die version.txt erstellung und auslese angepasst werden

REM Das Reperaturtool als Teil des Installers.bat, soll anders als der Updater standartmäßig jedesmal ausgeführt werden und alles überprüfen
REM z.B. soll es einige Aufgaben von Funktionen aus CB.bat, wie ':abhängigkeiten', ':process_requirements' abnehmen
REM Dabei meine ich zum Einen z.B. die Überprüfung aller Pfade, also auch die Abstimmung mit vorhandenen Dateien aus ':abhängigkeiten'
REM Zum Anderen meine ich dabei z.B. das Herunterladen fehlender Tools/Dateien und die Überwachung der Ordnerstruktur aus ':process_requirements'

REM Der Installer.bat könnte dann z.B. auch CB.bat herunterladen, in dem CB -Verzeichnis einsortieren und Verknüpfungen zum Programm anlegen
REM Dabei soll eine interaktive Installation ermöglicht werden, bei welcher direkt pfade und einstellungen angegeben werden können
REM Dann muss er sich irgendwie selber in die ordnerstruktur einfügen, also dahin verschieben

REM Funktions-Settings: Sicherheitskopieautomatik, Sortierfunktion, Einstellung zur Art des speicherns. Z.B. Auswahl zwischen .txt, .xlsx, ...
REM und weitere Tool-Einstellungen, wie z.B. 

REM Löschen von CB.bat etc. über externes Tool (z.B. Installer?)

REM CB_Observe.bat: Logs, Errorhandling, etc.

:storage_settings
cls
echo Storage-Settings
echo.
echo (1) Programmspeicher verschieben.
echo (2) Programm löschen.
echo (3) Zu den Einstellungen zurückkehren.
echo.
set /p cho="> "
if /i "%cho%"=="1" goto :program_storage
if /i "%cho%"=="2" goto :del_program REM z.B. nur Hauptspeicher oder alles
if /i "%cho%"=="3" goto :settings
echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
timeout /t 3
goto :storage_settings

:del_program
cls
echo Storage-Settings-Deletion
echo.
echo Welche(r) Speicher soll gelöscht werden?
echo (1) Hauptspeicher.
echo (2) Hauptspeicher + Systemspeicher.
echo (3) Zu den Speichereinstellungen zurückkehren.
echo.
set /p cho="> "
if /i "%cho%"=="1" (
    cls
    echo Storage-Settings-Deletion-Mainstorage
    echo.
    echo %color_warning%[WARNING] Bist du dir sicher, dass der gesamte Hauptspeicher ["%color_warning_highlight%%Storage%\CB%color_reset%%color_warning%"] gelöscht werden soll? ^(y/n^)%color_reset%
    echo %color_warning%[WARNING] Sofern keine Sicherheitskopien vorliegen, werden auch %color_warning_highlight%alle Kassenbucheinträge%color_reset%%color_warning% gelöscht werden!%color_reset%
    echo.
    set /p confirm="> "
    if /i "%confirm%"=="y" (
        cls
        call :handle_deletion "1"
        goto :del_program
    )
    if /i "%confirm%"=="n" (
        echo %color_info%[INFO] Das Löschen wurde abgebrochen.%color_reset%
        echo %color_status%[STATUS] Kehre zu den Speicherlöschungseinstellungen zurück...%color_reset%
        echo.
        timeout /t 3
        goto :del_program
    )
    echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
    timeout /t 3
    goto :del_program
)
if /i "%cho%"=="2" (
    cls
    echo Storage-Settings-Deletion-Whole
    echo.
    echo %color_warning%[WARNING] Bist du dir sicher, dass das gesamte Programm ["%color_warning_highlight%CB.bat%color_reset%%color_warning%"] samt Hauptspeicher ["%color_warning_highlight%%Storage%\CB%color_reset%%color_warning%"] und Systemspeicher ["%color_warning_highlight%%TEMP%\CB%color_reset%%color_warning%"] gelöscht werden soll? ^(y/n^)%color_reset%
    echo %color_warning%[WARNING] Sofern keine Sicherheitskopien vorliegen, werden auch %color_warning_highlight%alle Kassenbucheinträge%color_reset%%color_warning% gelöscht werden!%color_reset%
    echo.
    set /p confirm="> "
    if /i "%confirm%"=="y" (
        cls
        call :handle_deletion "2"
        goto :del_program
    )
    if /i "%confirm%"=="n" (
        echo %color_info%[INFO] Das Löschen wurde abgebrochen.%color_reset%
        echo %color_status%[STATUS] Kehre zu den Speicherlöschungseinstellungen zurück...%color_reset%
        echo.
        timeout /t 3
        goto :del_program
    )
    echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
    timeout /t 3
    goto :del_program
)
if /i "%cho%"=="3" goto :storage_settings
echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
timeout /t 3
goto :storage_settings

:handle_deletion
    REM 1: Nur Hauptspeicher; 2: Alles
    set "mode=%~1"
    if "%mode%"=="1" (
        rmdir /S /Q "%Storage%\CB"
        call :handle_error "Löschen des Hauptspeichers"
        goto :eof
    )
    if "%mode%"=="2" (
        echo %color_info%[INFO] Vollständiger Löschprozess ist gestartet...%color_reset%
        rmdir /S /Q "%Storage%\CB"
        call :handle_error "Löschen des Hauptspeichers"
        rmdir /S /Q "%TEMP%\CB"
        call :handle_error "Löschen des Systemspeichers"
        :: temporäre deinstallationsdatei für CB.bat
        set "CB_Remove=%~dp0CB_Remove.bat"
        echo setlocal enabledelayedexpansion>>"%CB_Remove%"
        echo set "color_reset=[0m">>"%CB_Remove%"
        echo set "color_status=[36m">>"%CB_Remove%"
        echo set "color_info=[32m">>"%CB_Remove%"
        echo cls>>"%CB_Remove%"
        echo %color_status%[STATUS] CB.bat wird deinstalliert...%color_reset%>>"%CB_Remove%"
        echo timeout /t 6 /nobreak>>"%CB_Remove%"
        echo del CB.bat>>"%CB_Remove%"
        echo timeout /t 3>>"%CB_Remove%"
        echo %color_info%[INFO] CB.bat wurde erfolgreich deinstalliert.%color_reset%>>"%CB_Remove%"
        echo exit>>"%CB_Remove%"
        call :handle_error "Schreiben von CB_Remove.bat"

        echo %color_info%[INFO] Löschen von CB.bat beginnt...%color_reset%

        cd /d "%~dp0" && start CB_Remove.bat
        call :handle_error "Starten von CB_Remove.bat"
        timeout /t 3
        exit
        goto :eof
    )
    echo %color_error%[ERROR] Ungültiger Parameter "%mode%". Erwartet 1 oder 2.
    exit /b 1

:program_storage
cls
echo Storage-Settings-Move
echo.
echo Welche(r) Speicher sollen verschoben werden?
:: echo (1) Sicherheits-Speicher ["%temp%\CB"].
echo (1) Hauptspeicher ["%Storage%\CB"].
echo (2) Alle aufgeführten Speicher.
echo (3) Zu den Speicher-Einstellungen zurückkehren.
echo.
set /p cho="> "

if /i "%cho%"=="1" (
    cls
    echo Storage-Settings-Mainstorage
    echo.
    echo Bitte gib das Verzeichnis an, in welches der Hauptspeicher verschoben werden soll:
    echo.
    set /p "n_storage="
    cls
    echo Storage-Settings-Mainstorage
    echo.
    echo %color_warning%[WARNING] Soll der Hauptspeicher ["%color_warning_highlight%%Storage%\CB%color_reset%%color_warning%"] wirklich in das Verzeichnis ["%color_warning_highlight%%n_storage%%color_reset%%color_warning%"] verschoben werden? ^(y/n^)%color_reset%
    echo.
    set /p confirm="> "
    if /i "%confirm%"=="y" (
        cls
        call :handle_storage
        call :handle_error "Verschieben des Hauptspeichers"
        goto :program_storage
    )
    if /i "%confirm%"=="n" (
        echo %color_info%[INFO] Das Verschieben wurde abgebrochen.%color_reset%
        echo %color_status%[STATUS] Kehre zu den Speicherverschiebungseinstellungen zurück...%color_reset%
        echo.
        timeout /t 3
        goto :program_storage
    )
    echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
    timeout /t 3
    goto :program_storage
)
if /i "%cho%"=="2" (
    cls && echo soon && pause && goto :program_storage
)
if /i "%cho%"=="3" goto :storage_settings
echo %color_error%[ERROR] Ungültige Eingabe.%color_reset%
timeout /t 3
goto :program_storage

:handle_storage
    :: Variablen definieren
    set "SRC=%TEMP%\CB\path.txt"
    :: Überprüfe, ob die Datei existiert
    if not exist "%SRC%" (
        call :handle_error "%SRC%"
        exit /b 1
    )

    :: Zweite Zeile der Datei einlesen
    set "i=0"
    for /f "usebackq delims=" %%A in ("%SRC%") do (
        set /a i+=1
        if !i! equ 2 (
            set "Storage=%%A"
            goto :read_done
        )
    )
    :read_done

    :: Aktualisieren der path.txt
    set "i=0"
    > "%TEMP%\CB\path.tmp" (
        for /f "usebackq delims=" %%A in ("%SRC%") do (
            set /a i+=1
            if !i! equ 2 (
                rem echo der neue Pfad
                echo(!n_storage!
            ) else (
                rem echo alle anderen Zeilen unverändert
                echo(%%A
            )
        )
    )
    rem Datei austauschen ohne Rückfrage
    move /Y "%TEMP%\CB\path.tmp" "%SRC%" > nul
    call :handle_error "Verschieben von "%TEMP%\CB\path.tmp" nach "%SRC%""

    :: Hauptspeicher vom alten zum neuen Speicherort verschieben
    robocopy "%Storage%\CB" "%n_storage%\CB" /MOVE /E
    call :handle_error "Verschieben von '%Storage%\CB' nach '%n_storage%'"
    goto :eof

:: Funktion für Abhängigkeiten
:abhängigkeiten
    :: Überprüfe, ob die Datei existiert und Definition der Hauptvariablen
    if exist "%TEMP%\CB\path.txt" (
        set "i=0"
        for /f "usebackq delims=" %%A in ("%TEMP%\CB\path.txt") do (
            set /a i+=1
            if !i! equ 2 (
                set "Storage=%%A"
                goto :break_loop
            )
        )
        :break_loop
        :: Abstimmung der Ortsvariable von CB.bat
        set /p "cb_path=" < "%TEMP%\CB\path.txt"
        if not "%cb_path%" equ "%~dp0" (
            (
                echo "%~dp0"
                for /f "usebackq skip=1 delims=" %%A in ("%TEMP%\CB\path.txt") do echo %%A
            ) > "%TEMP%\CB\path.txt"
        )
    ) else (
        :: set "Storage=%userprofile%\Desktop"
        set "Storage=%appdata%"
    )
    set /p version=<"%Storage%\CB\System\Files\Temp\version.txt"

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

    :: Variablen für :make_entry
    set "CashBalanceFile=Kassenbestand(NICHT_LOESCHEN).txt"
    set "CreateExcelFile=%Storage%\CB\System\Tools\CreateExcel.ps1"

    :: Variablen für die logs
    "logfile_outpud=%Storage%\CB\System\Files\Temp\Logs\output.log"
    "logfile_error=%Storage%\CB\System\Files\Temp\Logs\errors.log"

    goto :eof
    :: oder exit /b

:: Funktion zum Verarbeiten der requirements.txt
:process_requirements
    set "file=%TEMP%\CB\requirements.txt"

    :: Überprüfen, ob die Datei existiert
    if not exist "%file%" (
        echo %color_error%[ERROR] Die Datei "%file%" wurde nicht gefunden!%color_reset%
        echo %color_status%[STATUS] Baue die Umgebung '%TEMP%\CB'.%color_reset%
        mkdir "%TEMP%\CB"
        echo %~dp0>"%TEMP%\CB\path.txt"
        echo %Storage%>>"%TEMP%\CB\path.txt"
        echo %color_info%[INFO] Der Bau der Umgebung '%TEMP%\CB' wurde erfolgreich abgeschlossen.%color_reset%
        echo %color_status%[STATUS] Lade requirements.txt herunter.%color_reset%
        curl -o "%TEMP%\CB\requirements.txt" https://raw.githubusercontent.com/necrqum/cashbook/main/requirements.txt
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
    echo %color_status%[STATUS] Schreibe die Datei 'colors.bat'.%color_reset%
    echo set "color_reset=[0m">>"%Storage%\CB\System\Tools\Temp\colors.bat"
    echo set "color_info=[32m">>"%Storage%\CB\System\Tools\Temp\colors.bat"
    echo set "color_warning=[33m">>"%Storage%\CB\System\Tools\Temp\colors.bat"
    echo set "color_error=[31m">>"%Storage%\CB\System\Tools\Temp\colors.bat"
    echo set "color_status=[36m">>"%Storage%\CB\System\Tools\Temp\colors.bat"
    echo set "color_info_highlight=[42;37m">>"%Storage%\CB\System\Tools\Temp\colors.bat"
    echo set "color_warning_highlight=[43;37m">>"%Storage%\CB\System\Tools\Temp\colors.bat"
    echo set "color_error_highlight=[41;37m">>"%Storage%\CB\System\Tools\Temp\colors.bat"
    echo set "color_status_highlight=[46;37m">>"%Storage%\CB\System\Tools\Temp\colors.bat"
    echo %color_info%[INFO] Die Datei '%Storage%\CB\System\Tools\Temp\colors.bat' wurde erfolgreich geschrieben.%color_reset%
    echo %color_info%[INFO] Alle Schritte erfolgreich abgeschlossen!%color_reset%
    call :abhängigkeiten
    goto :eof

:: Funktion zum Verarbeiten des Updaters
:counter
    if exist "%Storage%\CB\System\Files\Temp\counted.txt" (
        set /p count=<"%Storage%\CB\System\Files\Temp\counted.txt"
        echo !count!
        if !count! GEQ 5 (
            echo 0 >"%Storage%\CB\System\Files\Temp\counted.txt"
            REM xcopy /s /i "%userprofile%\Desktop\Kassenbuch" "F:\Backup\Kassenbuch_%DATE%"
            goto :handle_update
        ) else (
            set /a n_count=!count! + 1
            echo !n_count! >"%Storage%\CB\System\Files\Temp\counted.txt"
        )
    ) else (
        echo 0 >"%Storage%\CB\System\Files\Temp\counted.txt"
        set Info=1
    )
    goto :eof

: Update Behandlung
:handle_update
cd /d "%Storage%\CB\System\Tools\" && start CB_Update.bat
:: call :handle_error "Programm starten" >> %logfile_outpud% 2>> %logfile_error%
call :handle_error "Programm starten"

timeout /t 2 /nobreak
:A
if exist "%TEMP%\CB\shutdown.flag" (
    if exist "%TEMP%\CB\shutdown2.flag" (
        del "%TEMP%\CB\shutdown.flag"
        del "%TEMP%\CB\shutdown2.flag"
        goto :main_menu
    )
    cls
    echo %color_status%[STATUS] Es wird nach Updates gesucht...%color_reset%
    echo %color_warning%[WARNING] Bitte beenden Sie nicht das Programm.%color_reset%
    timeout /t 3 /nobreak > nul
    goto :A
) else (
    exit
)

:: Auslesen des Datums
:get_date
    set "Datum=%DATE%"
    set "day=!Datum:~0,2!"
    set "month=!Datum:~3,2!"
    set "year=!Datum:~-4!"
    goto :eof

:math
    goto :eof

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