// F#: a discriminated union for orders and a pipeline over them.
module Sample

open System

type Status =
    | Pending
    | Paid of paidOn: DateTime
    | Cancelled of reason: string

type Order = { Number: int; Total: decimal; Status: Status }

let describe order =
    match order.Status with
    | Pending -> sprintf "#%d pending" order.Number
    | Paid on -> sprintf "#%d paid on %s" order.Number (on.ToString "yyyy-MM-dd")
    | Cancelled reason when reason.Length > 0 -> sprintf "#%d cancelled: %s" order.Number reason
    | Cancelled _ -> sprintf "#%d cancelled" order.Number

let orders =
    [ { Number = 1; Total = 120.50m; Status = Paid (DateTime(2026, 9, 24)) }
      { Number = 2; Total = 0m; Status = Cancelled "duplicate" }
      { Number = 3; Total = 42m; Status = Pending } ]

let revenue =
    orders
    |> List.filter (fun o -> match o.Status with Paid _ -> true | _ -> false)
    |> List.sumBy (fun o -> o.Total)

orders |> List.iter (describe >> printfn "%s")
printfn "revenue: %M" revenue
