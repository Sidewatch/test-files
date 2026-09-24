## Nim: a typed inventory with a proc, an iterator and a template.
import std/[strformat, sequtils, algorithm]

const ReorderPoint = 25

type
  Item = object
    sku: string
    qty: int
    price: float

proc lowStock(items: seq[Item]): seq[Item] =
  ## Items at or below the reorder point, cheapest first.
  result = items.filterIt(it.qty <= ReorderPoint)
  result.sort(proc(a, b: Item): int = cmp(a.price, b.price))

iterator described(items: seq[Item]): string =
  for it in items:
    yield (if it.qty == 0: &"{it.sku}: out of stock" else: &"{it.sku}: {it.qty} left")

template timeIt(name: string, body: untyped) =
  let start = cpuTime()
  body
  echo name, " took ", cpuTime() - start, "s"

let items = @[Item(sku: "A-100", qty: 12, price: 4.5), Item(sku: "C-300", qty: 3, price: 99.0)]
for line in described(lowStock(items)):
  echo line
echo &"value: {items.mapIt(it.qty.float * it.price).foldl(a + b):.2f}"
