#!/usr/bin/env tclsh
# Tcl: parse orders, total the paid ones, and a proc with a default argument.

set REORDER_POINT 25
array set byStatus {}
set orders {}

proc describe {order {verbose 0}} {
    dict with order {
        if {$verbose} { return "#$number $status ([format %.2f $total])" }
        return "#$number $status"
    }
}

foreach line {"1,120.50,paid" "2,42,pending" "3,0,cancelled"} {
    lassign [split $line ,] number total status
    lappend orders [dict create number $number total $total status $status]
    incr byStatus($status)
}

set revenue 0.0
foreach o $orders {
    if {[dict get $o status] eq "paid"} { set revenue [expr {$revenue + [dict get $o total]}] }
    puts [describe $o 1]
}
puts "revenue: [format %.2f $revenue]"
foreach s [lsort [array names byStatus]] { puts "  $s: $byStatus($s)" }
