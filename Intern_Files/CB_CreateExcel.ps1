param (
    [int]$yearBalance,
    [int]$monthBalance,
    [int]$dayBalance,
    [string]$Workbookpath
)

$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $false

# Überprüfen, ob die Datei existiert
if (Test-Path $Workbookpath) {
    $Workbook = $Excel.Workbooks.Open($Workbookpath)
    $Sheet = $Workbook.Sheets.Item(1)
} else {
    $Workbook = $Excel.Workbooks.Add()
    $Sheet = $Workbook.Sheets.Item(1)
    
    # Initiale Kopfzeilen festlegen, wenn die Datei neu erstellt wird
    $Sheet.Cells.Item(1,1) = 'Cash Balance'
    $Sheet.Cells.Item(1,2) = 'Year'
    $Sheet.Cells.Item(1,3) = 'Month'
    $Sheet.Cells.Item(1,4) = 'Day'
    $Sheet.Cells.Item(1,5) = 'Date'
}

# Nächste freie Zeile finden
$nextRow = $Sheet.UsedRange.Rows.Count + 1

# Werte in die neue Zeile einfügen
$Sheet.Cells.Item($nextRow, 1) = 'Balance after calculations'
$Sheet.Cells.Item($nextRow, 2) = $yearBalance
$Sheet.Cells.Item($nextRow, 3) = $monthBalance
$Sheet.Cells.Item($nextRow, 4) = $dayBalance
$Sheet.Cells.Item($nextRow, 5) = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") # Aktuelles Datum und Uhrzeit hinzufügen

# Spalten automatisch anpassen
$Sheet.Columns.AutoFit()

# Excel-Datei speichern
$Workbook.SaveAs($Workbookpath)
$Workbook.Close()
$Excel.Quit()