# jq: summarise an orders array — revenue by status, top SKUs, a flat CSV.
def money: (. * 100 | round) / 100;

def revenue_by_status:
  group_by(.status)
  | map({ key: .[0].status, value: (map(.total) | add | money) })
  | from_entries;

def top_skus($n):
  [ .[] | .items[] ]
  | group_by(.sku)
  | map({ sku: .[0].sku, qty: (map(.quantity) | add) })
  | sort_by(-.qty)
  | .[:$n];

{
  count: length,
  revenue: revenue_by_status,
  top: top_skus(3),
  paid: [ .[] | select(.status == "paid" and .total > 100) | .number ]
}
| ., ( .paid[] | "\(.)" )
