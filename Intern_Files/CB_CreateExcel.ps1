param(
    [string]$operation,
    [string]$name,
    [string]$income,
    [string]$expenditure,
    [string]$Workbookpath,
    [string]$cashbalance
)

# Excel-Anwendung öffnen und Datei prüfen
$excelExists = Test-Path $Workbookpath
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

if ($excelExists) {
    $workbook = $excel.Workbooks.Open($Workbookpath)
} else {
    # Neues Workbook erstellen und Header festlegen
    $workbook = $excel.Workbooks.Add()
    $sheet = $workbook.Sheets.Item(1)
    $sheet.Name = "Kassenbuch"
    $sheet.Cells.Item(1, 1).Value = "Datum"
    $sheet.Cells.Item(1, 2).Value = "Vorgang"
    $sheet.Cells.Item(1, 3).Value = "Name"
    $sheet.Cells.Item(1, 4).Value = "Einnahme"
    $sheet.Cells.Item(1, 5).Value = "Ausgabe"
    $sheet.Cells.Item(1, 6).Value = "Kassenbestand"
}

$sheet = $workbook.Sheets.Item(1)
$lastRow = $sheet.UsedRange.Rows.Count + 1

# Neue Zeile hinzufügen
$sheet.Cells.Item($lastRow, 1).Value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$sheet.Cells.Item($lastRow, 2).Value = $operation
$sheet.Cells.Item($lastRow, 3).Value = $name
$sheet.Cells.Item($lastRow, 4).Value = $income
$sheet.Cells.Item($lastRow, 5).Value = $expenditure
$sheet.Cells.Item($lastRow, 6).Value = $cashbalance

# Spaltenbreite automatisch anpassen
for ($col = 1; $col -le 6; $col++) {
    $sheet.Columns.Item($col).AutoFit()
}

# Arbeitsmappe speichern und schließen
$workbook.SaveAs($Workbookpath)
$workbook.Close()
$excel.Quit()