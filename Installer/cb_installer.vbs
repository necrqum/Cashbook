Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Zielverzeichnis für die Installation festlegen (Desktop)
strUserprofile = objShell.ExpandEnvironmentStrings("%Userprofile%")
strInstallDir = objFSO.BuildPath(strUserprofile, "Desktop", "elektronisches KB")

' Überprüfen, ob das Programm bereits installiert ist
If Not objFSO.FolderExists(strInstallDir) Then
    ' URL zum Herunterladen der Anwendung
    strDownloadURL = "http://www.beispiel.com/Kassenbuch.zip"
    ' Temporäres Verzeichnis für den Download
    strTempDir = objFSO.BuildPath(objShell.ExpandEnvironmentStrings("%TEMP%"), "KassenbuchTemp")
    ' Temporäre Datei für den Download
    strTempFile = objFSO.BuildPath(strTempDir, "Kassenbuch_temp.zip")
    
    ' PowerShell-Skript für das Herunterladen der Datei
    strPowerShellScript = "Invoke-WebRequest -Uri """ & strDownloadURL & """ -OutFile """ & strTempFile & """"
    
    ' PowerShell-Skript ausführen, um die Datei herunterzuladen
    objShell.Run "powershell.exe -ExecutionPolicy Bypass -Command """ & strPowerShellScript & """", 0, True
    
    ' Zip-Datei entpacken
    objShell.Run "powershell.exe Expand-Archive """ & strTempFile & """ """ & strTempDir & """", 0, True
    
    ' Anwendung in das Installationsverzeichnis kopieren
    objFSO.CopyFolder strTempDir, strInstallDir
    
    ' Temporäres Verzeichnis löschen
    objFSO.DeleteFolder strTempDir, True
    
    ' Meldung, dass die Installation abgeschlossen ist
    MsgBox "Die Installation von MeineApp wurde erfolgreich abgeschlossen.", vbInformation, "Installation abgeschlossen"
Else
    ' Meldung, dass das Programm bereits installiert ist
    MsgBox "Das Programm ist bereits installiert.", vbInformation, "Installation übersprungen"
End If