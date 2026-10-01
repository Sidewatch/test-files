' ── Comments ───────────────────────────────────────────────
' Line comment. TODO: persist the stock. FIXME: rounding.
REM Old-style remark comment
''' <summary>
''' XML doc comment for the warehouse module.
''' </summary>
''' <param name="sku">The stock keeping unit.</param>
''' <returns>The matching item.</returns>
''' <remarks>See <see cref="Warehouse.Item"/>.</remarks>

' ── Compiler options, imports, preprocessor ────────────────
Option Explicit On
Option Strict On
Option Infer On
Option Compare Binary

Imports System
Imports System.Collections.Generic
Imports System.Linq
Imports System.Text
Imports Col = System.Collections.Generic
Imports <xmlns:inv="https://example.com/inventory">

#Const DEBUG_MODE = True
#If DEBUG_MODE Then
    ' debug build
#ElseIf TRACE Then
    ' trace build
#Else
    ' release build
#End If
#Region "Types"
#End Region
#ExternalSource("generated.vb", 10)
#End ExternalSource

<Assembly: System.Reflection.AssemblyTitle("Warehouse")>

Namespace Warehouse

    ' ── Constants and enums ────────────────────────────────
    Public Module Constants
        Public Const ReorderPoint As Integer = 25
        Public Const AppName As String = "Warehouse"
        Public Const Ratio As Double = 0.75
    End Module

    Public Enum Status As Integer
        Pending = 0
        Paid = 1
        Cancelled
    End Enum

    <Flags>
    Public Enum Perm
        None = 0
        Read = &H1
        Write = &H2
        Exec = &O4
    End Enum

    ' ── Interfaces, delegates, structures ──────────────────
    Public Interface IDescribable
        ReadOnly Property Tag As String
        Function Describe() As String
    End Interface

    Public Delegate Function Reducer(acc As Integer, value As Integer) As Integer

    Public Structure Point
        Public X As Integer
        Public Y As Integer
        Public Sub New(x As Integer, y As Integer)
            Me.X = x
            Me.Y = y
        End Sub
    End Structure

    Public Class StockException
        Inherits Exception
        Public Sub New(message As String)
            MyBase.New(message)
        End Sub
    End Class

    ' ── Class with properties, events, operators ───────────
    <Serializable>
    Public MustInherit Class Entity
        Implements IDescribable

        Private Shared _instances As Integer = 0
        Protected _qty As Integer
        Friend dirty As Boolean = False
        Private ReadOnly _sku As String
        Public Shared ReadOnly Empty As New Item("", 0)

        Public Event Restocked(amount As Integer)
        Public Event LowStock As EventHandler

        Public Sub New(sku As String)
            _sku = sku
            _instances += 1
        End Sub

        Protected Overrides Sub Finalize()
            _instances -= 1
            MyBase.Finalize()
        End Sub

        Public ReadOnly Property Sku As String
            Get
                Return _sku
            End Get
        End Property

        Public Property Qty As Integer
            Get
                Return _qty
            End Get
            Set(value As Integer)
                _qty = If(value < 0, 0, value)
            End Set
        End Property

        Public Property Price As Decimal = 1D
        Public Property Tags As String() = {}
        Public Property State As Status = Status.Pending

        Public MustOverride Function Describe() As String Implements IDescribable.Describe
        Public Overridable ReadOnly Property Tag As String Implements IDescribable.Tag
            Get
                Return "item"
            End Get
        End Property

        Protected Sub RaiseRestocked(amount As Integer)
            RaiseEvent Restocked(amount)
        End Sub
    End Class

    Public NotInheritable Class Item
        Inherits Entity
        Implements IComparable(Of Item)

        Public Sub New(sku As String, qty As Integer)
            MyBase.New(sku)
            Me.Qty = qty
        End Sub

        Public Overrides Function Describe() As String
            Return $"{Sku}: {Qty} left (${Price:F2})"
        End Function

        Public Function CompareTo(other As Item) As Integer Implements IComparable(Of Item).CompareTo
            Return Qty.CompareTo(other.Qty)
        End Function

        Public Shared Operator +(a As Item, b As Item) As Item
            Return New Item(a.Sku, a.Qty + b.Qty)
        End Operator

        Public Shared Operator =(a As Item, b As Item) As Boolean
            Return a.Sku = b.Sku
        End Operator

        Public Shared Operator <>(a As Item, b As Item) As Boolean
            Return a.Sku <> b.Sku
        End Operator

        Public Shared Widening Operator CType(i As Item) As String
            Return i.Sku
        End Operator

        Public Sub Restock(Optional amount As Integer = 1, ByRef Optional note As String = "")
            Qty += amount
            RaiseRestocked(amount)
        End Sub

        Public Function Sum(ParamArray values() As Integer) As Integer
            Return values.Sum()
        End Function

        Public Iterator Function Countdown(n As Integer) As IEnumerable(Of Integer)
            For i As Integer = n To 1 Step -1
                Yield i
            Next
        End Function

        Public Async Function LoadAsync() As Task(Of Integer)
            Await Task.Delay(10)
            Return 42
        End Function
    End Class

    Public Class Box(Of T As {Class, New})
        Public Content As T
        Public Function Make(Of U As Structure)() As U
            Return Nothing
        End Function
    End Class

    Public Class Collection
        Default Public Property Item(index As Integer) As String
            Get
                Return ""
            End Get
            Set(value As String)
            End Set
        End Property
    End Class

    Partial Public Class Item
    End Class

End Namespace

' ── Module with main logic ─────────────────────────────────
Module Program
    Declare Auto Function MessageBox Lib "user32.dll" Alias "MessageBoxW" (hWnd As IntPtr, text As String) As Integer

    Private WithEvents timer As New System.Timers.Timer(1000)

    Sub Literals()
        Dim plain As String = "double ""quoted"" with doubled quotes"
        Dim interp As String = $"item {plain.Length,5:N0} and {If(True, "yes", "no")} and {{literal}}"
        Dim multi As String = $"line one
line two"
        Dim c As Char = "x"c
        Dim dec As Integer = 42
        Dim hex As Integer = &HFF
        Dim oct As Integer = &O17
        Dim bin As Integer = &B1010_1010
        Dim sep As Long = 1_000_000L
        Dim l As Long = 123L
        Dim s As Short = 5S
        Dim ui As UInteger = 7UI
        Dim f As Single = 1.5F
        Dim d As Double = 1.5E-3
        Dim m As Decimal = 12.5D
        Dim dt As Date = #3/1/2026 9:30:00 AM#
        Dim t As Boolean = True
        Dim fl As Boolean = False
        Dim nothing As Object = Nothing
        Dim xml = <inv:item sku="WGT-100"><qty><%= dec %></qty><!-- comment --></inv:item>
        Dim attr = xml.@sku
        Dim kids = xml.<inv:qty>
        Dim all = xml...<inv:qty>
    End Sub

    Sub Main(args As String())
        Dim items As New List(Of Warehouse.Item) From {
            New Warehouse.Item("WGT-100", 12) With {.Price = 4.5D},
            New Warehouse.Item("GDG-200", 40),
            New Warehouse.Item("GZM-300", 0)
        }

        ' operators
        Dim n As Integer = 10
        n += 1 : n -= 1 : n *= 2 : n /= 2 : n \= 3 : n ^= 2 : n <<= 1 : n >>= 1
        Dim s As String = "a"
        s &= "b"
        Dim arith = (1 + 2) * 3 - 4 / 5 \ 6 Mod 7 ^ 2
        Dim logic = Not True And False Or True Xor False AndAlso True OrElse False
        Dim cmp = n < 1 OrElse n > 2 OrElse n <= 3 OrElse n >= 4 OrElse n = 5 OrElse n <> 6
        Dim isIt = items(0) Is items(1) OrElse items(0) IsNot Nothing
        Dim likeIt = "WGT-100" Like "WGT-*"
        Dim typeChecks = TypeOf items(0) Is Warehouse.Item
        Dim ternary = If(n > 5, "big", "small")
        Dim coalesce = If(Nothing, "default")
        Dim cast = CType(n, Double) + CInt(2.5) + DirectCast(CObj(3), Integer) + TryCast(CObj(s), String).Length
        Dim nameOf1 = NameOf(items)
        Dim typeIs = GetType(Warehouse.Item)
        Dim lambda = Function(x As Integer) x * 2
        Dim sub1 = Sub(x As Integer) Console.WriteLine(x)
        Dim multiLine = Function(x As Integer)
                            Return x + 1
                        End Function
        Dim query = From i In items
                    Where i.Qty > 0 AndAlso i.Qty <= Warehouse.Constants.ReorderPoint
                    Order By i.Qty Descending, i.Sku
                    Group By i.State Into Count(), Total = Sum(i.Qty)
                    Select State, Count, Total
        Dim joined = From a In items Join b In items On a.Sku Equals b.Sku Select a.Sku Take 5 Skip 1
        Dim arr() As Integer = {1, 2, 3}
        Dim grid(2, 2) As Integer
        ReDim Preserve arr(5)
        Dim nullable As Integer? = Nothing
        Dim tuple As (sku As String, qty As Integer) = ("WGT-100", 12)
        Dim x As Integer = Nothing

        ' control flow
        If n > 5 Then
            Console.WriteLine("big")
        ElseIf n > 2 Then
            Console.WriteLine("medium")
        Else
            Console.WriteLine("small")
        End If
        If n = 0 Then Console.WriteLine("zero") Else Console.WriteLine("nonzero")

        For i As Integer = 0 To 10 Step 2
            If i = 4 Then Continue For
            If i = 8 Then Exit For
        Next
        For Each o As Warehouse.Item In items
            Console.WriteLine(o.Describe())
        Next
        While n > 0
            n -= 1
            If n = 3 Then Exit While
        End While
        Do
            n += 1
        Loop While n < 3
        Do Until n > 10
            n += 5
            Continue Do
        Loop

        Select Case n
            Case 1, 2
                Console.WriteLine("low")
            Case 3 To 9
                Console.WriteLine("mid")
            Case Is > 100
                Console.WriteLine("huge")
            Case Else
                Console.WriteLine("other")
        End Select

        Try
            Throw New Warehouse.StockException("empty")
        Catch ex As Warehouse.StockException When ex.Message.Length > 0
            Console.Error.WriteLine(ex.Message)
        Catch ex As Exception
            Throw
        Finally
            Console.WriteLine("done")
        End Try

        Using sw As New System.IO.StringWriter()
            sw.Write("hello")
        End Using
        SyncLock items
            items.Clear()
        End SyncLock
        With items(0)
            .Price = 1D
        End With

        On Error Resume Next
        On Error GoTo ErrHandler
        GoTo Done
ErrHandler:
        Resume Next
Done:
        AddHandler timer.Elapsed, AddressOf OnTick
        RemoveHandler timer.Elapsed, AddressOf OnTick
        Console.WriteLine($"revenue: {items.Sum(Function(o) o.Price * o.Qty):F2}")   ' 120.50
        Stop
        End
    End Sub

    Private Sub OnTick(sender As Object, e As EventArgs) Handles timer.Elapsed
    End Sub

    Function Fib(n As Integer) As Integer
        If n < 2 Then Return n
        Fib = Fib(n - 1) + Fib(n - 2)
        Exit Function
    End Function
End Module

' ── Modifiers, events, interfaces, generics ────────────────
Namespace Warehouse.Advanced

    Public Interface IProducer(Of Out T)
        Function Produce() As T
    End Interface

    Public Interface IConsumer(Of In T)
        Sub Consume(item As T)
    End Interface

    Public Interface IBoth
        Inherits IDisposable, IComparable
        Event Changed As EventHandler
        Property Name As String
        Default ReadOnly Property Item(i As Integer) As Object
    End Interface

    Public Delegate Sub Notifier(message As String)

    Public MustInherit Class Base
        Public Overridable Sub Run()
        End Sub
        Public MustOverride Sub Stop2()
        Protected Friend Sub Both()
        End Sub
        Private Protected Sub Narrow()
        End Sub
        Public Overloads Sub Run(times As Integer)
        End Sub
        Public Shadows Sub Hide()
        End Sub
        Public NotOverridable Overrides Function ToString() As String
            Return MyClass.GetType().Name
        End Function
    End Class

    Public Class Derived
        Inherits Base
        Implements IBoth

        Private _name As String
        Private ReadOnly _items As New List(Of Object)
        Public WriteOnly Property Secret As String
            Set(value As String)
                _name = value
            End Set
        End Property

        Public Custom Event Changed As EventHandler Implements IBoth.Changed
            AddHandler(value As EventHandler)
                _items.Add(value)
            End AddHandler
            RemoveHandler(value As EventHandler)
                _items.Remove(value)
            End RemoveHandler
            RaiseEvent(sender As Object, e As EventArgs)
                For Each h As EventHandler In _items
                    h.Invoke(sender, e)
                Next
            End RaiseEvent
        End Event

        Public Property Name As String Implements IBoth.Name

        Default Public ReadOnly Property Item(i As Integer) As Object Implements IBoth.Item
            Get
                Return _items(i)
            End Get
        End Property

        Public Overrides Sub Stop2()
        End Sub

        Public Function CompareTo(obj As Object) As Integer Implements IComparable.CompareTo
            Return 0
        End Function

        Public Sub Dispose() Implements IDisposable.Dispose
            GC.SuppressFinalize(Me)
        End Sub

        Public Shared Operator IsTrue(x As Derived) As Boolean
            Return True
        End Operator

        Public Shared Operator IsFalse(x As Derived) As Boolean
            Return False
        End Operator

        Public Shared Operator -(x As Derived) As Derived
            Return x
        End Operator

        Public Shared Operator Not(x As Derived) As Derived
            Return x
        End Operator

        Public Shared Operator &(a As Derived, b As Derived) As Derived
            Return a
        End Operator

        Public Shared Operator Like(a As Derived, b As String) As Boolean
            Return True
        End Operator

        Public Shared Narrowing Operator CType(s As String) As Derived
            Return New Derived()
        End Operator

        Partial Private Sub OnLoaded()
        End Sub
    End Class

    Public Class Constraints(Of T As {IComparable(Of T), New}, U As Class, V As Structure)
        Public Sub Process(Of W As IDisposable)(item As W)
        End Sub
    End Class

    Public Module Extensions
        <System.Runtime.CompilerServices.Extension()>
        Public Function Doubled(ByVal value As Integer) As Integer
            Return value * 2
        End Function
    End Module

End Namespace

' ── Statements and keywords not yet used ───────────────────
Module MoreStatements
    Const Pi As Double = 3.14159
    Dim shared1 As Integer

    Sub Demo()
        Static counter As Integer = 0
        Const local As Integer = 5
        Dim arr(5) As Integer
        Dim jagged()() As Integer = New Integer()() {}
        Dim s As String = "hello"
        Mid(s, 1, 1) = "J"
        Call Console.WriteLine("call statement")
        Erase arr
        Dim obj As Object = Nothing
        Dim res = TypeOf obj IsNot Nothing
        Dim d = New Dictionary(Of String, List(Of Integer))()
        Dim t As (Integer, String) = (1, "a")
        Dim i As Integer = CInt(Fix(2.5))
        Dim c = CChar("a") & CStr(1) & CShort(1) & CUInt(1) & CULng(1) & CSByte(1) & CUShort(1) & CDate("2026-01-01") & CObj(1) & CDec(1)
        Dim q = From x In {1, 2, 3} Let y = x * 2 Where y > 2 Order By y Skip While y < 0 Take While y < 100 Select y Distinct
        Dim agg = Aggregate x In {1, 2} Into Sum(x), Average(x), Min(x), Max(x), Any(x > 1), All(x > 0), LongCount()
        Dim gj = From a In {1} Group Join b In {1} On a Equals b Into g = Group Select a
        Dim pt = From x In {1, 2, 3, 4} Skip 1 Take 2 Select x
        Dim ns = GetXmlNamespace()
        Dim line = 1 +
                   2 _
                   + 3
        Dim lambdaInline = Function(a As Integer, b As Integer) a + b
        Dim asyncLambda = Async Function() As Task
                              Await Task.Delay(1)
                          End Function
        Dim myValue = My.Computer.Name & My.Application.Info.Version.ToString() & My.Settings.ToString()
        Dim global1 = Global.System.Math.PI
        Dim nullableCheck = If(CType(Nothing, Integer?), 0)
        Dim isNothing = obj Is Nothing
        If TypeOf obj Is String AndAlso DirectCast(obj, String).Length > 0 Then Exit Sub
        Do : counter += 1 : Loop While counter < 3
        For Each kv As KeyValuePair(Of String, List(Of Integer)) In d
            Continue For
        Next
        Select Case True
            Case i < 0
            Case Else
        End Select
        Try
            Throw New ArgumentNullException(NameOf(s))
        Catch ex As ArgumentException
            Exit Try
        End Try
        Using a As New IO.MemoryStream(), b As New IO.MemoryStream()
        End Using
        GoTo Label1
Label1:
        Return
    End Sub

    Public Async Sub FireAndForget()
        Await Task.Yield()
    End Sub

    Public Function Fact(n As Integer) As Long
        If n <= 1 Then Return 1
        Return n * Fact(n - 1)
    End Function

    Public Property Auto As Integer = 5
    Public ReadOnly Property Lazy As String = "x"
    Public Event Done As Action(Of Integer)

End Module
