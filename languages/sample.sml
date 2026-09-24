(* Standard ML: a datatype, a record, pattern matching and a fold. *)
datatype status = Pending | Paid of real | Cancelled of string

type order = { number : int, total : real, status : status }

fun describe ({ number, status, ... } : order) =
  case status of
      Pending => "#" ^ Int.toString number ^ " pending"
    | Paid on => "#" ^ Int.toString number ^ " paid (" ^ Real.toString on ^ ")"
    | Cancelled "" => "#" ^ Int.toString number ^ " cancelled"
    | Cancelled reason => "#" ^ Int.toString number ^ " cancelled: " ^ reason

fun revenue orders =
  List.foldl (fn (o : order, acc) => case #status o of Paid _ => acc + #total o | _ => acc) 0.0 orders

val orders = [ { number = 1, total = 120.5, status = Paid 20260924.0 }
             , { number = 2, total = 0.0, status = Cancelled "duplicate" }
             , { number = 3, total = 42.0, status = Pending } ]

val () = List.app (fn o => print (describe o ^ "\n")) orders
val () = print ("revenue: " ^ Real.fmt (StringCvt.FIX (SOME 2)) (revenue orders) ^ "\n")
