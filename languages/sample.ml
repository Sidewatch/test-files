(* OCaml: a variant for order status, a record, and a fold over a list. *)
type status = Pending | Paid of float | Cancelled of string

type order = { number : int; total : float; status : status }

let describe = function
  | { number; status = Pending; _ } -> Printf.sprintf "#%d pending" number
  | { number; status = Paid on; _ } -> Printf.sprintf "#%d paid (%.0f)" number on
  | { number; status = Cancelled reason; _ } when reason <> "" -> Printf.sprintf "#%d cancelled: %s" number reason
  | { number; _ } -> Printf.sprintf "#%d cancelled" number

let revenue orders =
  List.fold_left (fun acc o -> match o.status with Paid _ -> acc +. o.total | _ -> acc) 0.0 orders

module StatusSet = Set.Make (String)

let () =
  let orders = [ { number = 1; total = 120.5; status = Paid 20260924. }
               ; { number = 2; total = 0.; status = Cancelled "duplicate" }
               ; { number = 3; total = 42.; status = Pending } ] in
  List.iter (fun o -> print_endline (describe o)) orders;
  Printf.printf "revenue: %.2f\n" (revenue orders)
