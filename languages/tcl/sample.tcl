#!/usr/bin/env tclsh
# ── Comments ──
# Tcl: warehouse stock tools. A comment is a command position starting with '#'.
# TODO: read the ledger from SQLite
# FIXME: the report ignores the locale
set note "semicolon then comment" ;# trailing comment after a semicolon

# ── Package and namespace setup ──
package require Tcl 8.6
package require http
package require msgcat
package provide inventory 1.4.0
package ifneeded inventory 1.4.0 [list source [file join [file dirname [info script]] inventory.tcl]]

namespace eval ::inventory {
    variable REORDER_POINT 25
    variable ledger [dict create]
    namespace export describe restock report
    namespace ensemble create
}

# ── Variables and substitution ──
set REORDER_POINT 25
set name "North Depot"
set greeting "Hello, $name! Total: [expr {1 + 2}]"
set braced {No $substitution here, nor [commands], nor \escapes}
set bare word
set quoted "multi word \"escaped quote\" and \\ backslash"
set escapes "tab\there newline\n bell\a backspace\b formfeed\f return\r vtab\v"
set numeric "octal \101 hex \x41 unicode é long \U0001F3ED"
set joined "line one \
            continued onto line two"
set unicode "Zürich ✓ 🏭"
set array_item $ledger(ABC-1)
set braced_var ${name}
set nested_var ${::inventory::REORDER_POINT}
set cmd_sub [string toupper $name]
set deep [lindex [list a [list b c]] 1 0]
unset -nocomplain scratch
append name " (main)"
incr REORDER_POINT 5
incr REORDER_POINT -5
global REORDER_POINT
variable local_counter 0
upvar 1 caller_var local_view
uplevel 1 {set caller_var 1}

# ── Numbers and expressions ──
set results [list \
    [expr {42}] [expr {-7}] [expr {3.14}] [expr {1.5e10}] [expr {0x1F}] [expr {0o17}] [expr {0b1010}] \
    [expr {1_000}] [expr {Inf}] [expr {-Inf}] [expr {NaN}] \
    [expr {1 + 2 - 3 * 4 / 5 % 6}] [expr {2 ** 10}] [expr {7 / 2.0}] [expr {int(7 / 2)}] \
    [expr {1 << 4 >> 1}] [expr {6 & 3 | 4 ^ 1}] [expr {~5}] [expr {!0}] \
    [expr {1 < 2 && 2 <= 3 || 3 > 4}] [expr {1 == 1 && 2 != 3}] \
    [expr {"a" eq "a" && "a" ne "b"}] [expr {"x" in {x y z}}] [expr {"w" ni {x y z}}] \
    [expr {1 ? "yes" : "no"}] [expr {abs(-3) + sqrt(16) + pow(2, 3) + max(1, 2) + min(1, 2)}] \
    [expr {round(2.5) + floor(2.7) + ceil(2.1) + double(3) + entier(4.0)}] \
    [expr {sin(0) + cos(0) + tan(0) + atan2(1, 1) + exp(0) + log(1) + log10(10)}] \
    [expr {rand() < 1 && srand(1) >= 0}] \
    [expr {$REORDER_POINT > 20 && [string length $name] > 3}] \
    [expr {true && !false}] [expr {yes || no}] [expr {on && !off}] \
]

# ── Procedures ──
proc describe {order {verbose 0}} {
    dict with order {
        if {$verbose} {
            return "#$number $status ([format %.2f $total])"
        }
        return "#$number $status"
    }
}

proc sum {args} {
    set total 0
    foreach n $args { incr total $n }
    return $total
}

proc with_defaults {a {b 2} {c "three"} args} {
    return [list $a $b $c $args]
}

proc ::inventory::restock {sku {amount 1}} {
    variable ledger
    dict incr ledger $sku $amount
    return [dict get $ledger $sku]
}

proc greet {who} {
    set msg [string cat "Hello, " $who]
    puts stdout $msg
    return -code ok -level 0 $msg
}

proc apply_twice {f x} { apply $f [apply $f $x] }
proc lambda_demo {} { apply {{x y} {expr {$x + $y}}} 1 2 }

rename greet salute
interp alias {} hello {} salute

# ── Control flow ──
if {$REORDER_POINT > 20} {
    puts "high"
} elseif {$REORDER_POINT > 10} {
    puts "medium"
} else {
    puts "low"
}

switch -exact -- $name {
    "North Depot" { puts "north" }
    "South Depot" -
    "East Depot"  { puts "other depot" }
    default       { puts "unknown" }
}

switch -glob -nocase -- $name {
    n* { puts "starts with n" }
    default { }
}

switch -regexp -matchvar groups -indexvar idx -- "ABC-12" {
    {^([A-Z]+)-(\d+)$} { puts "sku [lindex $groups 1] #[lindex $groups 2]" }
}

switch $name "North Depot" "puts one" default "puts two"

for {set i 0} {$i < 3} {incr i} {
    if {$i == 1} continue
    puts "i=$i"
}

set j 0
while {$j < 5} {
    incr j
    if {$j > 3} break
}

foreach {k v} {a 1 b 2} { puts "$k=$v" }
foreach x {1 2 3} y {a b c} { puts "$x$y" }
foreach item [list alpha beta gamma] { puts $item }

# ── Error handling ──
set rc [catch {expr {1 / 0}} err opts]
if {$rc} { puts "error: $err" }

try {
    error "boom" "custom info" 42
} trap {ARITH DIVZERO} {msg opts} {
    puts "divzero"
} on error {msg opts} {
    puts "caught: $msg [dict get $opts -errorcode]"
} on ok {result} {
    puts "fine"
} finally {
    puts "cleanup"
}

proc risky {} {
    return -code error -errorcode {INVENTORY OUT_OF_STOCK} "no stock"
}
if {[catch {risky} msg]} { puts "caught: $msg" }
throw {INVENTORY INVALID} "bad quantity"

# ── Lists ──
set orders {}
foreach line {"1,120.50,paid" "2,42,pending" "3,0,cancelled"} {
    lassign [split $line ,] number total status
    lappend orders [dict create number $number total $total status $status]
}
set numbers {5 3 9 1}
puts [lsort -integer -decreasing $numbers]
puts [lsort -unique -dictionary {b a B A}]
puts [lsearch -exact $numbers 9]
puts [lsearch -all -glob {apple apricot banana} a*]
puts [lrange $numbers 1 end-1]
puts [lreplace $numbers 1 1 X Y]
puts [linsert $numbers end Z]
puts [lreverse $numbers]
puts [lmap n $numbers {expr {$n * 2}}]
puts [lrepeat 3 x]
puts [llength $numbers]
puts [lindex $numbers end]
puts [lset numbers 0 99]
puts [concat {a b} {c d}]
puts [join $numbers ", "]
puts [split "a:b:c" :]
puts [lassign {1 2 3} first second]
lappend numbers 7
lsort -command {apply {{a b} {expr {$a - $b}}}} $numbers

# ── Dictionaries ──
set d [dict create sku ABC-1 qty 12]
dict set d price 2.5
dict set d tags primary 1
dict unset d price
dict for {key val} $d { puts "$key -> $val" }
dict update d qty q { incr q }
puts [dict exists $d sku]
puts [dict keys $d]
puts [dict values $d]
puts [dict size $d]
puts [dict get $d tags primary]
puts [dict getdef $d missing default]
puts [dict merge $d {extra 1}]
puts [dict filter $d key q*]
puts [dict map {k v} $d {string toupper $v}]

# ── Arrays ──
array set byStatus {}
foreach s {paid paid pending cancelled} { incr byStatus($s) }
foreach s [lsort [array names byStatus]] { puts "  $s: $byStatus($s)" }
puts [array exists byStatus]
puts [array size byStatus]
puts [array get byStatus]
array unset byStatus pend*
set matrix(0,0) 1
set matrix(1,1) 2
parray matrix

# ── Strings ──
puts [string length $name]
puts [string index $name 0]
puts [string range $name 0 4]
puts [string toupper $name][string tolower $name][string totitle $name]
puts [string trim "  x  "][string trimleft "xxa" x][string trimright "axx" x]
puts [string map {a 1 b 2} "abc"]
puts [string match {[A-Z]*-[0-9]*} "ABC-1"]
puts [string first "-" "ABC-1"][string last "-" "A-B-C"]
puts [string compare a b][string equal a a][string is integer 42][string is alpha abc]
puts [string repeat ab 3][string reverse abc][string replace abcdef 1 2 XY]
puts [string cat a b c]
puts [string wordend "hello world" 0][string wordstart "hello world" 7]
puts [format "%-10s|%5d|%08.3f|%x|%o|%e|%c|%%" "name" 42 3.14159 255 8 12345.678 65]
puts [scan "ABC-12" "%3s-%d" prefix digits]
puts [regexp {^([A-Z]+)-(\d+)$} "ABC-12" whole letters digits]
puts [regexp -nocase -all -inline {\d+} "a1b22c333"]
puts [regsub -all {\s+} "a   b \t c" " "]
puts [regsub -nocase {(\w+)@(\w+)} "user@example" {\2 at \1}]
puts [subst {Total: [expr {1 + 2}] for $name}]
puts [subst -nocommands -novariables {$name [expr 1]}]

# ── Files, channels, time ──
set fh [open /tmp/inventory.txt w]
puts $fh "ABC-1,12"
puts -nonewline $fh "ABC-2,400"
flush $fh
close $fh
if {[file exists /tmp/inventory.txt]} {
    set fh [open /tmp/inventory.txt r]
    set data [read $fh]
    close $fh
    puts [file size /tmp/inventory.txt]
    puts [file tail /tmp/inventory.txt][file dirname /tmp/inventory.txt][file extension /tmp/inventory.txt]
    puts [file join /tmp inventory.txt][file normalize ../x][file rootname a.txt]
    file delete -force /tmp/inventory.txt
}
puts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S" -timezone UTC]
puts [clock scan "2026-09-24" -format "%Y-%m-%d"]
puts [clock add [clock seconds] 7 days]
puts [time {expr {1 + 1}} 100]
puts [glob -nocomplain -directory /tmp -types f *.txt]
puts [pwd][cd /tmp][pwd]
puts [exec echo "from exec"]
puts [info exists REORDER_POINT][info commands puts][info procs desc*][info level]
puts [info script][info patchlevel][info hostname][info nameofexecutable]
fconfigure stdout -buffering line -encoding utf-8 -translation lf
fileevent stdin readable {puts "readable"}
after 100 {puts "later"}
after idle {puts "idle"}
set timer [after 5000 {puts "timeout"}]
after cancel $timer
vwait ::done
update
puts $::tcl_platform(os)
puts $::env(HOME)
puts $argc $argv $argv0

# ── Events, coroutines, OO ──
proc generator {} {
    yield 1
    yield 2
    return done
}
coroutine gen generator
puts [gen]
puts [gen]

oo::class create StockItem {
    variable sku quantity
    constructor {s q} {
        set sku $s
        set quantity $q
    }
    method describe {} { return "$sku x$quantity" }
    method remove {n} {
        if {$n > $quantity} { error "out of stock: $sku" }
        incr quantity -$n
    }
    forward desc my describe
    unexport remove
    destructor { puts "gone: $sku" }
}

oo::class create Perishable {
    superclass StockItem
    mixin Loggable
    variable expiry
    method expired? {} { return 0 }
}

oo::object create plain
set item [StockItem new ABC-1 12]
puts [$item describe]
$item destroy

namespace eval ::inventory {
    proc report {} {
        variable ledger
        dict for {sku qty} $ledger { puts [format "%-8s %5d" $sku $qty] }
    }
}
::inventory::restock ABC-1 12
inventory report
trace add variable REORDER_POINT write {apply {{name1 name2 op} {puts "changed"}}}
trace add execution puts enter {apply {{cmd op} {}}}
interp create sandbox
interp eval sandbox {set x 1}
interp delete sandbox
exit 0
