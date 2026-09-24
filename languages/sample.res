// ReScript: a variant, a record, and a pipe-first pipeline compiled to JS.
type status = Pending | Paid(float) | Cancelled(string)

type order = {number: int, total: float, status: status}

let describe = order =>
  switch order.status {
  | Pending => `#${order.number->Int.toString} pending`
  | Paid(on) => `#${order.number->Int.toString} paid (${on->Float.toString})`
  | Cancelled(reason) if reason != "" => `#${order.number->Int.toString} cancelled: ${reason}`
  | Cancelled(_) => `#${order.number->Int.toString} cancelled`
  }

let revenue = orders =>
  orders
  ->Array.filter(o =>
    switch o.status {
    | Paid(_) => true
    | _ => false
    }
  )
  ->Array.reduce(0.0, (acc, o) => acc +. o.total)

let orders = [
  {number: 1, total: 120.5, status: Paid(20260924.0)},
  {number: 2, total: 0.0, status: Cancelled("duplicate")},
  {number: 3, total: 42.0, status: Pending},
]

orders->Array.forEach(o => Console.log(describe(o)))
Console.log(`revenue: ${revenue(orders)->Float.toString}`)
