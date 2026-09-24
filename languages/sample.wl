(* Wolfram Language: orders as associations, a query, and a plot. *)
orders = {
  <|"number" -> 1, "total" -> 120.5, "status" -> "paid"|>,
  <|"number" -> 2, "total" -> 42, "status" -> "pending"|>,
  <|"number" -> 3, "total" -> 0, "status" -> "cancelled"|>,
  <|"number" -> 4, "total" -> 88.25, "status" -> "paid"|>
};

describe[o_Association] := StringForm["#`` `` ``", o["number"], o["status"], NumberForm[o["total"], {6, 2}]];

revenue = Total[#["total"] & /@ Select[orders, #["status"] == "paid" &]];

byStatus = GroupBy[orders, #["status"] &, Length];

Print /@ describe /@ orders;
Print["revenue: ", revenue];   (* 208.75 *)

ListLinePlot[#["total"] & /@ orders, PlotLabel -> "Order totals", PlotMarkers -> Automatic]
