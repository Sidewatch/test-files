' VBScript: total the paid orders from a CSV and write a report.
Option Explicit

Const REORDER_POINT = 25
Dim fso, file, line, parts, revenue, count

Set fso = CreateObject("Scripting.FileSystemObject")
Set file = fso.OpenTextFile("orders.csv", 1)
revenue = 0 : count = 0

Do Until file.AtEndOfStream
    line = Trim(file.ReadLine)
    If Len(line) > 0 And Left(line, 1) <> "#" Then
        parts = Split(line, ",")
        count = count + 1
        If LCase(parts(2)) = "paid" Then revenue = revenue + CDbl(parts(1))
    End If
Loop
file.Close

Function Describe(number, status)
    Describe = "#" & number & " (" & status & ")"
End Function

WScript.Echo count & " orders, revenue " & FormatNumber(revenue, 2)
If revenue > 1000 Then
    MsgBox "Good week!", vbInformation, "Report"
End If
