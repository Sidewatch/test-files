' ── Comments ───────────────────────────────────────────────
' VBScript: stock report for the warehouse. TODO: email the report. FIXME: locale.
REM Old-style remark comment
Rem another remark

'@ Option and directives
Option Explicit

' ── Constants ──────────────────────────────────────────────
Const REORDER_POINT = 25
Const APP_NAME = "Warehouse"
Const RATIO = 0.75
Const HEX_MASK = &HFF
Const OCT_MASK = &O17
Const BIG = 1.5E+3
Const ForReading = 1, ForWriting = 2, ForAppending = 8
Const vbCrLfTwice = vbCrLf & vbCrLf

' ── Variables ──────────────────────────────────────────────
Dim fso, file, line, parts, revenue, count
Dim items(2), grid(2, 2), dyn()
Dim sku, qty, price, nothingYet
Public publicVar
Private privateVar

' ── Literals ───────────────────────────────────────────────
Dim plain, quoted, tabbed, num, flt, dt, bln, nul, emp
plain = "double ""quoted"" with doubled quotes"
quoted = "He said ""stock is low"""
tabbed = "col1" & vbTab & "col2" & vbCrLf & "row2"
num = 42
flt = 3.14159
dt = #3/1/2026#
bln = True
bln = False
nul = Null
emp = Empty
nothingYet = Nothing

' ── Classes ────────────────────────────────────────────────
Class Item
    Private m_sku
    Private m_qty
    Public Price

    Private Sub Class_Initialize()
        m_qty = 0
        Price = 1.0
    End Sub

    Private Sub Class_Terminate()
        m_sku = Empty
    End Sub

    Public Property Get Sku()
        Sku = m_sku
    End Property

    Public Property Let Sku(value)
        m_sku = value
    End Property

    Public Property Get Qty()
        Qty = m_qty
    End Property

    Public Property Let Qty(value)
        If value < 0 Then value = 0
        m_qty = value
    End Property

    Public Property Set Owner(obj)
        Set m_owner = obj
    End Property

    Public Default Function Describe()
        Describe = m_sku & ": " & m_qty & " left"
    End Function
End Class

' ── Procedures ─────────────────────────────────────────────
Function Describe2(number, status)
    Describe2 = "#" & number & " (" & status & ")"
End Function

Function Fib(n)
    If n < 2 Then
        Fib = n
        Exit Function
    End If
    Fib = Fib(n - 1) + Fib(n - 2)
End Function

Sub Report(ByVal title, ByRef total)
    WScript.Echo title & ": " & FormatNumber(total, 2)
    total = total + 1
End Sub

Public Function Money(n)
    Money = FormatCurrency(n, 2)
End Function

' ── Main ───────────────────────────────────────────────────
Set fso = CreateObject("Scripting.FileSystemObject")
Set file = fso.OpenTextFile("orders.csv", ForReading)
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

' Operators
Dim a, b, r
a = 10 : b = 3
r = a + b - a * b / a \ b Mod 7 ^ 2
r = -a
r = "x" & "y"
r = Not True And False Or True Xor False Eqv True Imp False
r = (a < b) Or (a > b) Or (a <= b) Or (a >= b) Or (a = b) Or (a <> b)
r = (items(0) Is Nothing)

' Arrays
ReDim dyn(4)
ReDim Preserve dyn(9)
items(0) = "WGT-100"
grid(1, 1) = 5
Erase items

' Type conversion and built-ins
r = CInt("42") + CLng(7) + CSng(1.5) + CDbl("2.5") + CBool(1) + CByte(3) + CCur(1.25)
r = CStr(99) & TypeName(r) & VarType(r)
r = IsNumeric("12") And IsDate("2026-03-01") And IsArray(items) And IsEmpty(emp) And IsNull(nul) And IsObject(fso)
r = UCase("abc") & Mid("abcdef", 2, 3) & Right("abc", 1) & Replace("a-b", "-", "+") & InStr("abc", "b") & String(3, "*") & Space(2)
r = Now() & Date() & Time() & Year(Now) & DateAdd("d", 1, Date) & DateDiff("d", Date, Date)
r = Abs(-1) + Sqr(4) + Int(2.7) + Fix(-2.7) + Round(2.567, 2) + Sgn(-3) + Rnd() + Atn(1) + Log(2) + Exp(1)
Randomize

' Regular expressions
Dim re, matches, m
Set re = New RegExp
re.Pattern = "^[A-Z]{3}-\d+$"
re.IgnoreCase = True
re.Global = True
If re.Test("WGT-100") Then WScript.Echo "valid sku"
Set matches = re.Execute("WGT-100 GDG-200")
For Each m In matches
    WScript.Echo m.Value
Next

' Control flow
If revenue > 1000 Then
    MsgBox "Good week!", vbInformation + vbOKOnly, "Report"
ElseIf revenue > 500 Then
    WScript.Echo "ok week"
Else
    WScript.Echo "slow week"
End If
If count = 0 Then WScript.Echo "none" Else WScript.Echo count & " orders"

For i = 1 To 10 Step 2
    If i = 5 Then Exit For
Next
For Each m In matches
    WScript.Echo m
Next
While count > 0
    count = count - 1
Wend
Do While count < 3
    count = count + 1
    If count = 2 Then Exit Do
Loop
Do
    count = count - 1
Loop Until count <= 0

Select Case count
    Case 0
        WScript.Echo "zero"
    Case 1, 2
        WScript.Echo "few"
    Case Else
        WScript.Echo "many"
End Select

With fso
    WScript.Echo .GetBaseName("c:\stock\items.csv")
End With

' Error handling and statements
On Error Resume Next
Err.Clear
r = 1 / 0
If Err.Number <> 0 Then
    WScript.Echo "Error " & Err.Number & ": " & Err.Description & " (" & Err.Source & ")"
    Err.Raise vbObjectError + 1, "Report", "custom failure"
End If
On Error GoTo 0

Dim ex : ex = Eval("1 + 2")
Execute "WScript.Echo ""executed"""
ExecuteGlobal "Dim late : late = 1"
Set sh = CreateObject("WScript.Shell")
sh.Run "notepad.exe", 1, False
WScript.Sleep 100
Call Report("Revenue", revenue)
Report "Revenue", revenue
Set re = Nothing
WScript.Quit 0

' ── More built-ins, objects and syntax ─────────────────────
Dim dict, key, longText, ch, hx, oc, args, shell, net, env
Set dict = CreateObject("Scripting.Dictionary")
dict.CompareMode = 1
dict.Add "WGT-100", 12
dict("GDG-200") = 40
dict.Item("GZM-300") = 0
If dict.Exists("WGT-100") Then dict.Remove "WGT-100"
For Each key In dict.Keys
    WScript.Echo key & " = " & dict(key)
Next
WScript.Echo dict.Count & " keys; items: " & Join(dict.Items, ", ")

longText = "A long statement that continues " & _
           "on the next line " & _
           "and one more"
WScript.Echo longText : WScript.Echo "colon separated"

ch = Chr(65) & Chr(10) & ChrW(9731)
hx = Hex(255) & Oct(8) & Asc("A") & AscW("A")
WScript.Echo ch, hx, LCase(Trim(LTrim(RTrim("  x  ")))), StrReverse("abc"), StrComp("a", "b", 1), Len("abc")
WScript.Echo InStrRev("abcabc", "b"), Left("abc", 2), Mid("abc", 2), Filter(Array("a", "b"), "a")(0), UBound(Array(1, 2)), LBound(Array(1, 2))
WScript.Echo Array(1, 2, 3)(1), Join(Split("a,b,c", ","), "|"), UCase("x"), Space(3) & "|", String(2, "-")
WScript.Echo Timer, Hour(Now), Minute(Now), Second(Now), Month(Now), Day(Now), Weekday(Now), MonthName(1), WeekdayName(1), DatePart("yyyy", Now), DateSerial(2026, 3, 1), TimeSerial(9, 30, 0), DateValue("2026-03-01"), TimeValue("09:30:00")
WScript.Echo FormatDateTime(Now, vbShortDate), FormatPercent(0.75), FormatNumber(1234.5, 1), FormatCurrency(9.99)
WScript.Echo Escape("a b"), Unescape("a%20b"), Oct(8), Cos(0), Sin(0), Tan(0), Atn(1) * 4, Sgn(5), Hex(10)
WScript.Echo vbCr, vbLf, vbCrLf, vbNewLine, vbTab, vbNullChar, vbNullString, vbBack, vbFormFeed, vbVerticalTab
WScript.Echo vbBinaryCompare, vbTextCompare, vbEmpty, vbNull, vbInteger, vbLong, vbSingle, vbDouble, vbCurrency, vbDate, vbString, vbObject, vbError, vbBoolean, vbVariant, vbDataObject, vbDecimal, vbByte, vbArray
WScript.Echo vbOKOnly, vbOKCancel, vbYesNo, vbYesNoCancel, vbCritical, vbQuestion, vbExclamation, vbInformation, vbDefaultButton2, vbSystemModal, vbOK, vbCancel, vbYes, vbNo, vbRetry, vbIgnore, vbAbort
WScript.Echo vbSunday, vbMonday, vbUseSystemDayOfWeek, vbFirstJan1, vbFirstFourDays, vbFirstFullWeek, vbGeneralDate, vbLongDate, vbShortDate, vbLongTime, vbShortTime
WScript.Echo vbUseDefault, vbTrue, vbFalse, vbObjectError, vbProperCase, vbUpperCase, vbLowerCase

Set args = WScript.Arguments
If args.Count > 0 Then WScript.Echo args(0)
WScript.Echo WScript.ScriptName & WScript.ScriptFullName & WScript.Version & WScript.FullName & WScript.Path
WScript.StdOut.WriteLine "to stdout"
WScript.StdErr.WriteLine "to stderr"
line = WScript.StdIn.ReadLine

Set shell = CreateObject("WScript.Shell")
Set net = CreateObject("WScript.Network")
Set env = shell.Environment("PROCESS")
WScript.Echo shell.ExpandEnvironmentStrings("%USERNAME%") & net.ComputerName & env("PATH")
shell.RegWrite "HKCU\Software\Acme\Warehouse\Count", 1, "REG_DWORD"
shell.Popup "Done", 5, "Report", vbInformation
Set app = GetObject("", "Excel.Application")
Set shortcut = shell.CreateShortcut("C:\stock.lnk")
Set conn = CreateObject("ADODB.Connection")
conn.Open "Provider=SQLOLEDB;Data Source=server.example.com;Integrated Security=SSPI"
Set rs = conn.Execute("SELECT sku, qty FROM items WHERE qty < " & REORDER_POINT)
Do While Not rs.EOF
    WScript.Echo rs("sku") & ": " & rs.Fields("qty").Value
    rs.MoveNext
Loop
rs.Close : conn.Close

Dim inputText
inputText = InputBox("Enter a SKU", "Lookup", "WGT-100")
If IsEmpty(inputText) Then WScript.Quit 1

Public Property Get Version2()
    Version2 = "2.0"
    Exit Property
End Property

Private Function Helper(ByVal a, Optional ByRef b)
    On Error Resume Next
    Helper = a
    Exit Function
End Function

Private Sub Cleanup()
    Exit Sub
End Sub

Dim value
value = 5 \ 2 : value = 5 Mod 2 : value = 2 ^ 3 : value = -value : value = Not value
value = True And False : value = True Or False : value = True Xor False : value = True Eqv False : value = True Imp False
value = "a" < "b" : value = (1 = 1) : value = (1 <> 2) : value = 1 >= 1 : value = 2 <= 3
value = &H7FFF& : value = &HFFFF& : value = 1E3 : value = 1.5E-3
value = #12/31/2026 11:59:59 PM# : value = #1/1/2026#
Set value = Nothing
Set value = New RegExp
Set value = GetRef("Cleanup")
Set value = Server.CreateObject("Scripting.FileSystemObject")
Response.Write "ASP-style: " & Request.QueryString("sku")
Session("count") = 1
Application.Lock : Application.UnLock
