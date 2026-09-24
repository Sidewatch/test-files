' VB.NET: a class with a property, a LINQ query and string interpolation.
Imports System
Imports System.Linq

Module Sample
    Public Enum Status
        Pending
        Paid
        Cancelled
    End Enum

    Public Class Order
        Public Property Number As Integer
        Public Property Total As Decimal
        Public Property State As Status = Status.Pending

        Public Sub New(number As Integer, total As Decimal)
            Me.Number = number
            Me.Total = total
        End Sub

        Public Function Describe() As String
            Return $"#{Number} {State} {Total:F2}"
        End Function
    End Class

    Sub Main()
        Dim orders = New List(Of Order) From {
            New Order(1, 120.5D) With {.State = Status.Paid},
            New Order(2, 42D),
            New Order(3, 0D) With {.State = Status.Cancelled}
        }

        Dim revenue = orders.Where(Function(o) o.State = Status.Paid).Sum(Function(o) o.Total)
        For Each o In orders
            Console.WriteLine(o.Describe())
        Next
        Console.WriteLine($"revenue: {revenue:F2}")   ' 120.50
    End Sub
End Module
