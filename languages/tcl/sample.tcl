#!/usr/bin/env tclsh
# Tcl 9.0 — syntax showcase
# ── Comments ──
# Tcl: warehouse stock tools. A comment is a command position starting with '#'.
# TODO: read the ledger from SQLite
# FIXME: the report ignores the locale
set note "semicolon then comment" ;# trailing comment after a semicolon

# ── Package and namespace setup ──
package require Tcl 9.0
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
    [expr {1e3}] [expr {.5 + 5.}] [expr {Inf}] [expr {-Inf}] [expr {NaN}] \
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
puts "$argc $argv $argv0"

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
# ── Command words: expansion, quoting forms, nesting ──
set parts {a b c}
puts {*}$parts
puts {*}{x y z}
puts {*}[list 1 2 3] {*}$parts
puts "nested [string cat "inner [string toupper "deep"]" suffix]"
puts "escaped \$dollar \[bracket\] \{brace\} \"quote\" \\backslash"
puts {braces keep \n and $x and [cmd] literal}
puts {nested {braces {three deep}} stay balanced}
puts "ok"; puts "two commands on one line" ; # then a comment
puts [list a b]; # comment after command
set empty ""
set empty2 {}
set varname name
puts [set $varname]
puts $name([string length x])
set ::global_via_ns 1
set ::inventory::qualified 2
puts ${::inventory::qualified}
puts $::inventory::qualified
puts "${name}_suffix $name\_suffix"
set array(key) value
set array(a,b) pair
set idx key
puts $array($idx) $array(a,b) ${array(key)}
puts "$array(key) and [set array(key)]"
puts "tab:\t octal:\101 hex:\x41 u4:é u8:\U0001F3ED newline-continued: \
    next"
puts é\x41\101\t
puts a\
     b
set multi {
    first line
    second line
}
set script {
    puts "evaluated later"
}
eval $script
eval puts hello world
uplevel #0 {set top_level 1}
upvar #0 ::inventory::ledger l
upvar 1 a b c d
global one two three
variable x 1 y 2

# ── Expressions: the full operator table ──
set a 6; set b 3; set flag 1
set ops [list \
    [expr {-$a}] [expr {+$a}] [expr {~$a}] [expr {!$flag}] \
    [expr {$a ** $b}] [expr {$a * $b}] [expr {$a / $b}] [expr {$a % $b}] \
    [expr {$a + $b}] [expr {$a - $b}] [expr {$a << 1}] [expr {$a >> 1}] \
    [expr {$a < $b}] [expr {$a > $b}] [expr {$a <= $b}] [expr {$a >= $b}] \
    [expr {$a == $b}] [expr {$a != $b}] [expr {"x" eq "y"}] [expr {"x" ne "y"}] \
    [expr {"x" in {x y}}] [expr {"x" ni {x y}}] \
    [expr {$a & $b}] [expr {$a ^ $b}] [expr {$a | $b}] \
    [expr {$a && $b}] [expr {$a || $b}] [expr {$flag ? $a : $b}] \
    [expr {($a + $b) * 2}] [expr {[llength $parts] > 2}] [expr {$array(key) eq "value"}] \
    [expr {0x1F + 0o17 + 0b101 + 1e3 + 1.5E-3}] \
    [expr {wide(3) + entier(2) + int(1.5) + double(1) + bool(1) + isqrt(16)}] \
    [expr {fmod(7, 3) + hypot(3, 4) + sinh(0) + cosh(0) + tanh(0) + asin(0) + acos(1) + atan(0)}] \
    [expr {abs(-1) + round(1.5) + floor(1.5) + ceil(1.5) + sqrt(4) + pow(2, 2)}] \
    [expr {srand(1) + rand()}] \
    [expr {max(1, 2, 3) + min(1, 2, 3)}] \
    [expr {1 <  2 ? "less" : "more"}] \
    [expr {true}] [expr {false}] [expr {yes}] [expr {no}] [expr {on}] [expr {off}] \
    [expr "$a + $b"] [expr $a + $b] [expr {$a} + {$b}] \
]
puts [expr {[string match a* abc] && ![string is digit abc]}]
puts [tcl::mathop::+ 1 2 3]
puts [tcl::mathop::< 1 2 3]
puts [tcl::mathop::** 2 3]
puts [tcl::mathfunc::max 1 2]
proc tcl::mathfunc::double_it {x} { expr {$x * 2} }
puts [expr {double_it(21)}]
namespace path {::tcl::mathop ::tcl::mathfunc}
puts [+ 1 2 3]

# ── Control flow: every spelling ──
if 1 then { puts "then keyword" } else { puts "else keyword" }
if {$flag} {puts yes} elseif {!$flag} {puts no} else {puts maybe}
if {[string match a* $name]} { puts a } else { puts other }
while 1 { break }
while {1} {
    break
}
for {set k 0} {$k < 3} {incr k} { puts $k }
for {set k 0; set m 10} {$k < $m} {incr k; incr m -1} {}
for {} {1} {} { break }
foreach {a1 b1} {1 2 3 4} {} 
foreach i {1 2} j {a b} k {x y} { puts $i$j$k }
foreach {key val} [dict create a 1 b 2] { puts "$key=$val" }
foreach var [list] {}
set squares [lmap n {1 2 3} { expr {$n * $n} }]
set odd [lmap n {1 2 3 4} { if {$n % 2 == 0} continue; set n }]
switch -exact -- abc {
    abc { puts exact }
    default { puts none }
}
switch -glob -- abc {
    a* - b* { puts "fall through" }
    default { puts none }
}
switch -regexp -nocase -- ABC {
    ^a { puts regexp }
}
switch -- $name {
    "North Depot" { puts north }
}
switch $name {
    a {} b {} default {}
}
switch -exact -matchvar mv -- x { x {} }
switch -- $name \
    one { puts 1 } \
    two { puts 2 } \
    default { puts other }
break_demo: ;# a label-like word is just a command name
catch {break}
catch {continue}
catch {return}
catch {error "e"} result options
catch {error "e"} result
catch {puts hi}
catch puts
return -code return
return -code break
return -code continue
return -code 5
return -options {-code ok} done
return -level 2 -code error -errorinfo "trace" -errorcode CODE "message"
tailcall puts "tailcall"
error "message" "info" {CODE 1}

# ── Procs: every parameter form, apply, tailcall ──
proc noargs {} { return }
proc oneargs {a} { return $a }
proc optional {a {b 1} {c {}}} { return [list $a $b $c] }
proc variadic {first args} { return [llength $args] }
proc args_only args { return $args }
proc braces_default {{x "a b"} {y {c d}}} { return $x$y }
proc ::ns::qualified {} {}
proc ::inventory::inner::deep {} {}
proc unusual\ name {} { return spaced }
proc {braced name} {} { return braced }
proc recursive {n} { expr {$n <= 1 ? 1 : $n * [recursive [expr {$n - 1}]]} }
proc upvar_demo {varName} { upvar 1 $varName v; incr v }
proc uplevel_demo {} { uplevel 1 {set x [expr {$x + 1}]} }
proc defaults_with_subst {{path [pwd]}} {}
proc procedural_return {} {
    if {1} { return early }
    return late
}
set lambda {{x} {expr {$x * 2}}}
puts [apply $lambda 21]
puts [apply {{x y} { expr {$x + $y} }} 1 2]
puts [apply [list {n} {incr n}] 1]
puts [apply {{x} {expr {$x}} ::inventory} 5]
set curried [list apply {{a b} {expr {$a + $b}}} 10]
puts [{*}$curried 5]
interp alias {} add10 {} apply {{a b} {expr {$a + $b}}} 10
trace add command oneargs rename {apply {{old new op} {}}}
trace remove command oneargs rename {apply {{old new op} {}}}
trace info variable REORDER_POINT
trace add variable x read {apply {{n1 n2 op} {}}}
trace add variable x {read write unset array} {apply {{n1 n2 op} {}}}
trace add execution oneargs {enter leave enterstep leavestep} {apply {{args} {}}}
trace variable REORDER_POINT w {apply {{n1 n2 op} {}}}

# ── New in Tcl 8.7 and 9.0: list, string, dict and file additions ──
puts [lseq 1 to 10]
puts [lseq 10 downto 1 by 3]
puts [lseq 5 .. 1]
puts [lseq 3]
puts [lseq 1 count 4 by 2]
puts [lpop numbers]
puts [lpop numbers end]
puts [lpop nested 0 1]
puts [lremove $numbers 0 2]
puts [ledit numbers 1 2 A B]
puts [lsearch -stride 2 -index 1 {a 1 b 2} 2]
puts [lsort -stride 2 -integer {a 3 b 1}]
puts [lsort -index 0 -ascii {{b 1} {a 2}}]
puts [lsort -indices {c a b}]
puts [lsort -bisect -integer {1 2 3} 2]
puts [lindex {a b c} end-1]
puts [lindex {{a b} {c d}} 1 0]
puts [lrange {a b c d} 1 end]
puts [string insert abcdef 3 XY]
puts [string is entier 0x10]
puts [string is dict {a 1}]
puts [string is list {a b}]
puts [string is boolean true][string is double 1.5][string is wideinteger 5][string is space " "]
puts [string is alnum a1][string is ascii a][string is control "\x01"][string is false no][string is graph a]
puts [string is lower a][string is upper A][string is print a][string is punct !][string is true yes][string is wordchar _][string is xdigit f]
puts [string index abc end-0]
puts [string range abc 1 end]
puts [string bytelength é][string length é]
puts [string equal -nocase -length 2 abc ABD]
puts [string compare -nocase abc ABC]
puts [string map -nocase {A 1} abc]
puts [string trim xxaxx x]
puts [dict getwithdefault $d missing fallback]
puts [dict getdef $d missing fallback]
puts [dict create a 1 b 2]
puts [dict lappend d key v1 v2]
puts [dict append d key more]
puts [dict incr d count 5]
puts [dict remove $d a]
puts [dict replace $d a 99]
puts [dict with d {}]
puts [dict info $d]
puts [dict update d a x b y { set x 1 }]
puts [dict for {k v} $d { break }]
puts [dict map {k v} $d { set v }]
puts [dict filter $d script {k v} { expr {$v > 1} }]
puts [dict filter $d value 1*]
puts [file tempdir]
puts [file tempfile fname]
puts [file home]
puts [file home someuser]
puts [file type /tmp]
puts [file isdirectory /tmp][file isfile /tmp][file exists /tmp][file executable /tmp][file readable /tmp][file writable /tmp]
puts [file mtime /tmp][file atime /tmp][file size /tmp][file owned /tmp]
puts [file attributes /tmp]
puts [file attributes /tmp -permissions]
puts [file split /a/b/c][file join a b c][file nativename /a/b][file separator][file volumes]
puts [file copy -force a b][file rename a b][file mkdir /tmp/x/y][file delete -force /tmp/x][file link -symbolic l target]
puts [file readlink l][file lstat l st][file stat /tmp st]
puts [file pathtype /a][file system /tmp][file channels]
puts [file dirname /a/b][file tail /a/b][file rootname /a/b.c][file extension /a/b.c][file normalize /a/../b]
puts [tcl::prefix match {apple banana} ap]
puts [tcl::prefix all {apple apricot} ap]
puts [tcl::prefix longest {apple apricot} a]
puts [zipfs mount /app.zip //zipfs:/app]
puts [zipfs list]
puts [zipfs exists //zipfs:/app/x]
puts [zipfs info //zipfs:/app/x]
puts [zipfs unmount //zipfs:/app]
puts [zipfs mkzip out.zip /dir]
puts [zipfs root]
puts [zipfs mkkey password]
puts [zipfs canonical /app.zip]
puts [zipfs lmkzip out.zip {a /x}]
puts [tcl::process list]
puts [tcl::process status 1]
puts [tcl::process autopurge]
puts [info cmdtype puts]
puts [info commands ::tcl::*]
puts [info coroutine]
puts [info class instances StockItem]
puts [info object class $item]
puts [info exists ::tcl_interactive]
puts [info library][info loaded][info sharedlibextension][info tclversion]
puts [info frame][info frame 0][info source puts]
puts [info default describe verbose v][info args describe][info body describe]
puts [info functions][info globals][info locals][info vars][info nameofexecutable][info cmdcount]
puts [info complete {puts "x"}][info hostname][info level 0][info patchlevel]

# ── Channels: chan, fconfigure, fcopy, sockets, pipes ──
set ch [open /tmp/data.bin {RDWR CREAT TRUNC}]
chan configure $ch -translation binary -buffering full -buffersize 4096 -encoding iso8859-1
chan puts $ch "line"
chan puts -nonewline $ch "no newline"
chan flush $ch
chan seek $ch 0 start
chan seek $ch -5 end
chan seek $ch 2 current
puts [chan tell $ch]
puts [chan gets $ch line]
puts [chan read $ch 10]
puts [chan read -nonewline $ch]
puts [chan eof $ch][chan blocked $ch][chan names][chan pending input $ch]
chan truncate $ch 0
chan event $ch readable {puts "readable"}
chan event $ch writable {}
chan push $ch transform_handler
chan pop $ch
chan close $ch
chan close $ch read
chan copy $ch stdout -size 100 -command {apply {{n args} {}}}
lassign [chan pipe] reader writer
chan create {read write} handler
fconfigure stdout -blocking 0 -buffering none -eofchar {} -translation {auto lf}
fconfigure $ch -mode 9600,n,8,1 -handshake none
fcopy stdin stdout
set p [open "|ls -l /tmp" r]
set p2 [open "|sort" r+]
set pids [pid $p]
puts [gets $p line]
puts [read $p]
puts [eof $p][tell $p][seek $p 0]
catch {close $p} err
set sock [socket -server accept 8080]
set client [socket localhost 8080]
set async [socket -async example.com 80]
fconfigure $sock -sockname
fconfigure $sock -peername
proc accept {chan addr port} { chan configure $chan -buffering line }
puts [exec ls -l | grep x]
puts [exec echo hi > /tmp/out]
puts [exec cat < /tmp/in 2>@1]
puts [exec echo hi >> /tmp/out 2>> /tmp/err &]
puts [exec -ignorestderr -keepnewline -- echo hi]
puts [exec echo hi |& cat]
puts [exec >&@stdout echo hi]
puts [exec sort << "input\ndata"]
puts [exec /bin/sh -c {echo $HOME}]
puts [read stdin 10][gets stdin][eof stdin][tell stdin]
puts [socket -myaddr 127.0.0.1 -myport 0 localhost 80]
puts stderr "to stderr"
puts -nonewline stdout "partial"
puts $ch "channel"
flush stderr
close $ch
source other.tcl
source -encoding utf-8 other.tcl
load libextension[info sharedlibextension] Extension
unload libextension[info sharedlibextension]
encoding system utf-8
encoding names
encoding convertto utf-8 "é"
encoding convertfrom utf-8 "\xc3\xa9"
encoding dirs
binary format a3c2s1 abc 1 2 3
binary scan "\x01\x02" cc a b
binary encode base64 "hello"
binary decode base64 "aGVsbG8="
binary encode hex "ab"
binary decode hex "6162"
binary encode uuencode "ab"
zlib compress "data"
zlib decompress $compressed
zlib crc32 "data"
zlib adler32 "data"
zlib gzip "data" -level 9
zlib gunzip $gz
zlib deflate "data"
zlib inflate $deflated
zlib stream compress
zlib push gzip $ch

# ── Time and events ──
puts [clock seconds][clock milliseconds][clock microseconds][clock clicks][clock clicks -milliseconds]
puts [clock format 0 -format {%a %A %b %B %c %C %d %D %e %F %g %G %h %H %I %j %k %l %m %M %n %N %p %P %s %S %t %T %u %U %V %w %W %x %X %y %Y %z %Z %%} -timezone :UTC -locale en_US]
puts [clock format 0 -format %Y-%m-%dT%H:%M:%SZ -gmt 1]
puts [clock scan "next friday" -base 0]
puts [clock scan "2026-01-01 00:00:00" -format "%Y-%m-%d %H:%M:%S" -timezone :Europe/London]
puts [clock add 0 1 month 2 weeks -3 days 4 hours 5 minutes 6 seconds -timezone :UTC]
puts [clock add 0 1 year]
puts [clock subtract 100 50 seconds]
puts [time {expr 1} 1000]
puts [timerate {expr 1} 1000]
after 0
after 10 [list puts "list form"]
after idle [list puts idle]
set id [after 100 {set done 1}]
puts [after info $id]
puts [after info]
after cancel $id
after cancel {set done 1}
update idletasks
vwait done
vwait ::inventory::state
yield
yieldto string cat
coroutine counter apply {{} { for {set i 0} {$i < 3} {incr i} { yield $i }; return -code break }}
puts [counter]
coroutine ::inventory::co apply {{} { yield [info coroutine] }}
coroutine inject_target eval {yield 1}
rename counter {}
puts [info coroutine]
puts [catch {counter} msg]

# ── Namespaces: every subcommand ──
namespace eval ::lib {
    variable count 0
    variable table
    array set table {}
    namespace export *
    namespace export add remove
    namespace export -clear
    namespace ensemble create -map {add ::lib::addImpl rm ::lib::rmImpl} -prefixes 0 -subcommands {add rm} -unknown ::lib::unk -parameters {ctx}
    namespace path {::tcl::mathop ::tcl::mathfunc}
    namespace import ::tcl::mathop::*
    namespace import -force ::other::cmd
    namespace unknown ::lib::resolver
    namespace upvar ::other var local
    proc addImpl {x} { variable count; incr count $x }
    proc rmImpl {x} { variable count; incr count -$x }
    proc unk {ens sub args} { return [list $ens addImpl] }
    proc resolver {args} {}
    proc where {} { namespace current }
}
puts [namespace children ::lib]
puts [namespace children ::lib *]
puts [namespace code {puts "scoped"}]
puts [namespace current]
puts [namespace delete ::lib::old]
puts [namespace ensemble create]
puts [namespace ensemble exists ::lib]
puts [namespace ensemble configure ::lib -map]
puts [namespace eval ::lib {namespace current}]
puts [namespace exists ::lib]
puts [namespace export]
puts [namespace forget ::lib::add]
puts [namespace import]
puts [namespace inscope ::lib {namespace current}]
puts [namespace origin ::lib::add]
puts [namespace parent ::lib::inner]
puts [namespace path]
puts [namespace qualifiers ::a::b::c][namespace tail ::a::b::c]
puts [namespace unknown]
puts [namespace which -command lib][namespace which -variable lib::count]
puts [lib add 5]
puts [::lib::where]
puts $::lib::count
puts $lib::count
variable ::lib::count
set ::lib::table(key) 1

# ── TclOO: classes, mixins, filters, properties, metaclasses ──
oo::class create Animal {
    variable name sound
    constructor {n {s "..."}} {
        set name $n
        set sound $s
        next
    }
    destructor { puts "$name is gone" }

    method speak {} { return "$name says $sound" }
    method rename {new} { set name $new }
    method private_helper {} {}
    method name {} { return $name }
    method NamedWithCaps {} {}
    method <=> {other} {}
    method + {other} {}

    export speak
    unexport private_helper
    forward say my speak
    forward cmd ::tcl::string::toupper
    filter logger
    method logger {args} { puts "calling [self target]"; next {*}$args }
    method varname {} { my varname name }
    method nsdemo {} { namespace current }
    method callback {} { return [callback speak] }
    method selfinfo {} { return "[self] [self class] [self object] [self namespace] [self method] [self caller] [self next] [self filter] [self target]" }
    method uplevel_demo {} { my variable name; uplevel 1 {} }
    method self_ns {} { self namespace }

    self method make {args} { return [my new {*}$args] }
    self export make

    property legs -get {...} -set {...}
    property -kind readable colour
    property -kind writable size -default 0
    variable -clear
    variable {*}{a b c}
}

oo::class create Dog {
    superclass Animal
    mixin Walker Swimmer
    variable tricks
    constructor {n} { next $n woof; set tricks {} }
    method speak {} { return "[next] loudly" }
    method learn {trick} { lappend tricks $trick }
    method tricks {} { return $tricks }
}

oo::define Dog method added {} { return added }
oo::define Dog {
    method another {} {}
    superclass -append Pet
    mixin -append Loud
    filter -clear
    variable extra
    constructor {} {}
    destructor {}
    renamemethod added renamed
    deletemethod renamed
    export speak
    unexport speak
    forward fwd ::puts
    self method meta {} {}
}
oo::objdefine $d method special {} { return special }
oo::objdefine $d { mixin Extra; filter {}; export special }
oo::objdefine $d forward f ::puts
oo::objdefine $d class Other
oo::define Dog class Meta
oo::class create Walker { method walk {} {} }
oo::class create Swimmer { method swim {} {} }
oo::abstract create Shape { method area {} {} }
oo::singleton create Config { method get {} {} }
oo::class create Meta { superclass oo::class; method describe {} {} }
oo::configurable create Settings { property host -default localhost; property port -default 80 }
Settings create s -host example.com -port 8080
puts [s configure]
s configure -port 81
puts [s configure -port]
set d [Dog new rex]
set d2 [Dog create fido buddy]
puts [$d speak][$d tricks]
puts [$d name]
puts [$d {*}{speak}]
puts [[Dog new x] speak]
puts [Dog new y]
puts [info object class $d][info object isa object $d][info object methods $d -all]
puts [info object namespace $d][info object variables $d][info object mixins $d][info object filters $d]
puts [info object forward $d fwd][info object call $d speak][info object definition $d speak]
puts [info class superclasses Dog][info class subclasses Animal][info class mixins Dog][info class methods Dog -all]
puts [info class constructor Dog][info class destructor Dog][info class definition Dog speak][info class variables Dog]
puts [info class filters Dog][info class forward Dog fwd][info class call Dog speak][info class instances Dog]
oo::copy $d $d2
oo::objdefine $d2 variable extra
rename $d {}
$d2 destroy
Dog destroy
oo::object create plain_obj
plain_obj destroy
oo::objdefine plain_obj method speak {} { return plain }
oo::define oo::class method new_hook {} {}
oo::define oo::object method extra {} {}
oo::class create Counter {
    variable n
    constructor {} { set n 0 }
    method incr {{by 1}} { incr n $by }
    method value {} { return $n }
    method unknown {name args} { return "unknown $name" }
}
Counter create c1
c1 incr
c1 incr 5
puts [c1 value]
puts [c1 nonexistent]
puts [c1 <cloned> ]
puts [Counter new]
my variable foo
my eval {}
my destroy
my <cloned> other
next
next 1 2
next {*}$args

# ── Messages, packages, testing, interpreters ──
package require msgcat
msgcat::mclocale en_gb
msgcat::mcset en_gb greeting "Hello"
msgcat::mcset fr greeting "Bonjour"
msgcat::mcmset de {hello Hallo bye Tschuess}
puts [msgcat::mc greeting]
puts [msgcat::mc "Hello %s, you have %d items" Ann 3]
puts [msgcat::mcn ::lib greeting]
puts [msgcat::mcexists greeting]
puts [msgcat::mcpackagelocale set fr]
puts [msgcat::mcloadedlocales loaded]
puts [msgcat::mcpreferences]
puts [msgcat::mcflset greeting "Hi"]
puts [msgcat::mcmax "a" "bb"]
puts [msgcat::mclocale]
namespace import msgcat::mc
puts [mc greeting]
package require tcltest 2.5
namespace import ::tcltest::*
configure -verbose {pass skip error}
test sku-1.1 {description of the test} -constraints {unix} -setup {set x 1} -body {
    expr {$x + 1}
} -cleanup {unset x} -result 2
test sku-1.2 {error case} -body { error boom } -returnCodes error -result boom
test sku-1.3 {regexp result} -body { string cat abc } -match regexp -result {^a.c$}
test sku-1.4 {output} -body { puts hi } -output "hi\n"
testConstraint extras [expr {[info commands extra] ne ""}]
cleanupTests
package require http 2.9
package require json
package require sqlite3
package require Thread
package require TclOO 1.0
package require platform
package require Tclx 8.4-
package require -exact inventory 1.4.0
package vcompare 1.2 1.10
package vsatisfies 1.4.0 1.0-
package present http
package names
package versions http
package provide inventory 1.4.0
package ifneeded inventory 1.4.0 {source inventory.tcl}
package forget inventory
package prefer stable
package unknown {apply {{name args} {}}}
package vsatisfies 9.0 8.6-9.0
package files inventory
package require Tcl 8.6-
set safe [interp create -safe]
interp eval $safe {expr 1}
interp alias $safe puts {} puts
interp expose $safe file
interp hide $safe exit
interp invokehidden $safe exit
interp limit $safe time -seconds [expr {[clock seconds] + 1}]
interp limit $safe command -value 1000
interp share {} stdout $safe
interp transfer {} $ch $safe
interp bgerror {} handler
interp debug {} -frame 1
interp issafe $safe
interp slaves
interp children
interp exists $safe
interp target $safe puts
interp aliases $safe
interp recursionlimit $safe 100
interp marktrusted $safe
interp cancel $safe
interp delete $safe
interp create -safe -- child
interp eval child {set x 1}
::safe::interpCreate sandboxed
::safe::interpDelete sandboxed
thread::create {thread::wait}
thread::send $tid {puts hi}
thread::mutex create
thread::cond create
thread::release $tid
tsv::set shared key value
tsv::get shared key
tsv::lappend shared list item
tsv::exists shared key
tsv::unset shared key
tpool::create -minworkers 1 -maxworkers 4
bgerror "message"
interp bgerror {} {apply {{msg opts} {}}}
history add {cmd}
history event 0
history info
history keep 100
history nextid
history redo 0
history substitute a b 0
history change {} 0
auto_load_index
auto_execok ls
auto_import pattern
auto_mkindex /dir *.tcl
auto_qualify cmd ::
auto_reset
tcl_findLibrary x 1.0 1.0 x.tcl XVAR xvar
parray ::env
parray array
exit
exit 0
