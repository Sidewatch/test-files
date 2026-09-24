#!/usr/bin/env nu
# Nushell: summarise a CSV of orders and report the top SKUs.

def money [n: float] { $"£($n | math round --precision 2)" }

# Load, filter and total the orders in a file
def "orders summary" [file: path, --min-total (-m): float = 0.0] {
    let orders = (open $file | where total > $min_total)
    {
        count: ($orders | length)
        revenue: ($orders | where status == paid | get total | math sum | money)
        by_status: ($orders | group-by status | transpose status rows | each { |r| { status: $r.status, n: ($r.rows | length) } })
    }
}

let summary = (orders summary orders.csv --min-total 10)
print $summary
$summary.by_status | sort-by n --reverse | first 3 | table
