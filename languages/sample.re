/* Reason: a variant, a record and a List fold — OCaml with a JS-flavoured syntax. */
type status =
  | Pending
  | Paid(float)
  | Cancelled(string);

type order = {
  number: int,
  total: float,
  status,
};

let describe = ({number, status, _}) =>
  switch (status) {
  | Pending => Printf.sprintf("#%d pending", number)
  | Paid(on) => Printf.sprintf("#%d paid (%.0f)", number, on)
  | Cancelled(reason) when reason != "" => Printf.sprintf("#%d cancelled: %s", number, reason)
  | Cancelled(_) => Printf.sprintf("#%d cancelled", number)
  };

let revenue = orders =>
  List.fold_left(
    (acc, o) =>
      switch (o.status) {
      | Paid(_) => acc +. o.total
      | _ => acc
      },
    0.0,
    orders,
  );

let orders = [
  {number: 1, total: 120.5, status: Paid(20260924.)},
  {number: 2, total: 0., status: Cancelled("duplicate")},
  {number: 3, total: 42., status: Pending},
];

List.iter(o => print_endline(describe(o)), orders);
Printf.printf("revenue: %.2f\n", revenue(orders));
