@echo off
setlocal enabledelayedexpansion

:: Farbcodes für Textausgabe
set "color_reset=[0m"
set "color_info=[32m"
set "color_warning=[33m"
set "color_error=[31m"
set "color_status=[36m"

:: Funktion zum Verarbeiten der requirements.txt
:process_requirements
    set "file=%TEMP%\KB\requirements.txt"

    :: Überprüfen, ob die Datei existiert
    if not exist "%file%" (
        echo %color_error%[ERROR] Die Datei "%file%" wurde nicht gefunden!%color_reset%
        mkdir "%TEMP%\KB"
        echo %color_status%[STATUS] Lade requirements.txt herunter.%color_reset%
        curl -o "%TEMP%\KB\requirements.txt" https://raw.githubusercontent.com/necrqum/cashbook/main/requirements.txt
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
        if "!line!"=="-Umgebung" (
            echo %color_info%[INFO] Modus "-Umgebung" erkannt!%color_reset%
            set "mode=environment"
            set "env_counter=0"
        ) else if "!line!"=="-Download" (
            echo %color_info%[INFO] Modus "-Download" erkannt!%color_reset%
            set "mode=download"
            set "download_counter=0"
        ) else if defined mode (
            :: Verarbeitung der Umgebungszeilen (Verzeichniserstellung)
            if "!mode!"=="environment" (
                set /a env_counter+=1
                set "env_path!env_counter!=!line!"
                
                echo %color_status%[STATUS] Verzeichnispfad !env_counter!: !line!%color_reset%

                :: Überprüfen, ob das Verzeichnis existiert
                if not exist "!line!" (
                    echo %color_warning%[INFO] Verzeichnis existiert nicht. Erstelle: !line!%color_reset%
                    mkdir "!line!"
                    if errorlevel 1 (
                        echo %color_error%[ERROR] Fehler beim Erstellen des Verzeichnisses: !line!%color_reset%
                        exit /b 1
                    ) else (
                        echo %color_info%[INFO] Verzeichnis erfolgreich erstellt: !line!%color_reset%
                    )
                ) else (
                    echo %color_info%[INFO] Verzeichnis existiert bereits: !line!%color_reset%
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
                    echo %color_status%[STATUS] Zielpfad für die Datei: !line!%color_reset%
                    
                    :: Extrahiere Dateiname aus URL
                    for %%B in ("!download_url1!") do set "filename=%%~nxB"
                    
                    :: Vollständiger Pfad zur Zieldatei
                    set "dest_file=!line!\!filename!"

                    :: Datei nur herunterladen, wenn sie nicht bereits existiert
                    if not exist "!dest_file!" (
                        echo %color_info%[INFO] Lade herunter: !download_url1! nach !dest_file!%color_reset%
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
    exit /b
endlocal