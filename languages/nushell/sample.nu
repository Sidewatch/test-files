#!/usr/bin/env nu
# Nushell 0.106 — syntax showcase: summarise a CSV of orders and report the top SKUs.
# TODO: stream large files instead of loading them
# FIXME: money() rounds half-even

use std/assert
use std log
use std/util *
source ./helpers.nu
overlay use ./stock.nu as stock --prefix

# ── Literals ──
let int_dec = 1_000
let int_hex = 0xFF
let int_oct = 0o755
let int_bin = 0b1010
let negative = -42
let float = 3.14
let sci = 1.5e-3
let inf = inf
let nan = NaN
let flag = true
let off = false
let nothing = null
let size = 10kb
let size2 = 1.5MiB
let dur = 2hr
let dur2 = 500ms
let dur3 = 1day + 3min + 4sec
let date = 2025-01-31
let datetime = 2025-01-31T12:30:00+01:00
let range = 1..10
let range_step = 1..2..10
let range_excl = 0..<5
let range_open = 3..
let glob = *.csv
let path = ./data/orders.csv
let bare = hello-world

# ── Strings ──
let dq = "double \"quoted\"\ttab\nnewline \u{1F4E6} \\ back"
let sq = 'single quoted, no escapes \n'
let bt = `back ticked path with spaces/file.txt`
let raw = r#'raw string with "quotes" and 'single' inside'#
let raw2 = r##'even #'# works'##
let interp = $"Item ($int_dec): ($float | math round --precision 1)"
let interp_sq = $'sku: ($negative)'
let interp_esc = $"literal \(parens\) and (1 + 2)"
let multi = "line one
line two"

# ── Collections ──
let list = [1 2 3 "four" [5 6] {a: 7}]
let list_commas = [1, 2, 3]
let rec = {name: "widget", qty: 12, tags: [a b], nested: {deep: true}, "quoted key": 1}
let tbl = [[sku qty]; [A-100 12] [B-200 0]]
let closure = {|x, y = 2| $x + $y }
let closure2 = {|| 42 }
let block = { print "inside block" }

# ── Commands and signatures ──
def money [n: float] { $"£($n | math round --precision 2)" }

# Load, filter and total the orders in a file
def "orders summary" [
    file: path,                            # the CSV to read
    --min-total (-m): float = 0.0,         # ignore small orders
    --verbose (-v),                        # print progress
    --format: string@"nu-complete formats", # output format
    ...extra: string                       # extra columns
]: nothing -> record {
    if $verbose { log info $"reading ($file)" }
    let orders = (open $file | where total > $min_total)
    {
        count: ($orders | length)
        revenue: ($orders | where status == paid | get total | math sum | money)
        by_status: ($orders | group-by status | transpose status rows | each { |r| { status: $r.status, n: ($r.rows | length) } })
    }
}

def "nu-complete formats" [] { ["table" "json" "csv"] }

def --env goto [dir: path] { cd $dir }
def --wrapped run [...rest] { ^echo ...$rest }
export def main [] { print "inventory" }
export def --env setup [] { $env.INVENTORY = "1" }
export-env { $env.PATH = ($env.PATH | prepend "/opt/inventory/bin") }
export const VERSION = "1.4.0"
export alias ll = ls -l
alias la = ls -a
extern "git status" [--short (-s)]
module stock { export def count [] { 5 } }
const LIMIT = 100

# ── Variables and environment ──
mut counter = 0
$counter += 1
$counter -= 1
$counter *= 2
$counter /= 2
$counter ++= 1
let $env_home = $env.HOME
$env.INVENTORY_DB = "stock.db"
$env.config.show_banner = false
let nested = $rec.nested.deep
let opt = $rec.missing?
let idx = $list.0
let cell = $tbl.sku.0
let spread = [...$list 8 9]
let rspread = {...$rec, extra: 1}

# ── Operators ──
let math = (1 + 2 - 3) * 4 / 2 // 3 mod 5 ** 2
let cmp = (1 < 2) and (2 <= 2) or (3 > 4) and not (4 >= 5)
let eq = (1 == 1) and (2 != 3)
let strs = ("abc" =~ "^a") and ("abc" !~ "z") and ("abc" starts-with "a")
let membership = (2 in [1 2 3]) and (4 not-in [1 2 3])
let bits = (0xF0 bit-and 0x3C) bit-or (1 bit-shl 4) bit-xor (256 bit-shr 2)
let concat = "a" ++ "b"
let has = ($rec | columns | any {|c| $c == "name" })
let xor = true xor false

# ── Control flow ──
if $counter > 5 {
    print "big"
} else if $counter > 2 {
    print "medium"
} else {
    print "small"
}

for i in 1..3 { print $i }
for item in $list { print $item }
mut n = 0
while $n < 5 {
    $n += 1
    if $n == 2 { continue }
    if $n == 4 { break }
}
loop { break }

let kind = match $counter {
    0 => "zero"
    1 | 2 => "few"
    $x if $x > 100 => "huge"
    {name: $n} => $n
    [$first, ..$rest] => $first
    _ => "many"
}

try { error make { msg: "bad input", label: {text: "here", span: (metadata $counter).span} } } catch { |err| print $err.msg }
try { 1 / 0 } catch { print "div" } finally { print "done" }
let result = do -i { ^false }
let ok = (do { 1 + 1 })
defer { print "bye" }

# ── Pipelines and externals ──
let summary = (orders summary orders.csv --min-total 10)
print $summary
ls | where size > 1kb and type == file | sort-by modified --reverse | select name size | first 5
open orders.csv | upsert total {|r| $r.qty * $r.price } | save --force out.json
^ls -la | lines | each {|l| $l | str trim } | where $it != ""
"hello world" | str replace "world" "nu" | str upcase | print
$summary.by_status | sort-by n --reverse | first 3 | table
http get https://example.com/api/orders | get items | update qty {|r| $r.qty + 1 }
ps | where cpu > 5 | get name | uniq | to json | save -f procs.json
let out = (^echo $"a(char nl)b" | complete)
echo $env.PWD o> out.log
echo err e> err.log
echo both o+e> both.log
let sub = $"(date now | format date '%Y-%m-%d')"
$list | each --keep-empty {|x| $x } | reduce --fold 0 {|it, acc| $acc + 1 }

# ── More Nushell: attributes, redirections, closures and special forms ──
@example "add two numbers" { add 1 2 } --result 3
@category "math"
@search-terms sum plus
@deprecated "use add2"
def add [a: int, b: int] { $a + $b }

def typed [
    a: int,
    b?: string,
    c: list<int> = [1 2 3],
    d: record<name: string, age: int> = {name: "x", age: 1},
    e: table<sku: string, qty: int> = [],
    f: any = null,
    g: oneof<int, string> = 5,
    h: closure = {|| 1 },
    i: duration = 1sec,
    j: filesize = 1kb,
    k: datetime,
    l: cell-path = $.a.b,
    m: range = 1..3,
    n: bool = false,
    o: binary = 0x[FF 00],
    p: glob = *.rs,
    q: number = 1.5,
    r: directory,
    s: error,
    t: nothing,
    u: string@"nu-complete formats"
]: [string -> string, nothing -> int] { "" }

# Binary and special literals
let bytes = 0x[de ad be ef]
let bits = 0b[1010 0101]
let octs = 0o[777]
let neg_dur = -5min
let frac_dur = 1.5hr
let pb = 1pb
let tib = 3TiB
let nan_val = NaN
let cellp = $.a.b.0
let opt_cell = $.a?.b!
let ranged = ..5
let ranged2 = (1..)
let rev = 5..1
let step_neg = 10..-2..0
let date_only = 2025-12-25
let date_neg = 2025-12-25T10:00:00-05:00
let rawstr = r'single #'
let bare_dots = ../parent/file.txt
let home = ~/dir
let glob_q = ?.txt

# Pipelines and redirections
ls | where name =~ '\.nu$' | each {|f| $f.name | path basename }
^ls -la | complete | get stdout
^ls o>| lines
^cargo build e>| lines
^cmd o+e>| str trim
^cmd out> out.txt err> err.txt
^cmd out>> append.txt
^cmd err>> errs.txt
^cmd out+err> both.txt
echo hi | save -a log.txt
echo hi | tee { save copy.txt } | print
ls | par-each {|f| $f.size } | math sum
[1 2 3] | each {|x| $x * 2 } | where {|x| $x > 2 } | enumerate | flatten
[[a b]; [1 2] [3 4]] | to csv | from csv | transpose -r -d
{a: 1, b: 2} | items {|k, v| $"($k)=($v)" } | str join ","
$in | default 0 | into int
"1,2" | split row "," | into int | math max
open --raw file.bin | into binary | bytes length
echo $nu.home-path $nu.os-info.name $nu.pid $nu.cwd $nu.config-path $nu.current-exe
echo $env.CURRENT_FILE $env.FILE_PWD $env.PROCESS_PATH
let pipe_meta = (metadata ($in))
do --ignore-errors --capture-errors { ^false }
source-env env.nu
hide-env FOO
hide cd
use std/dirs [add next prev]
use std/iter *
export use ./module.nu [helper]
export extern "my-cmd" [--flag (-f), arg?: string]
export module nested { export def inner [] { 1 } }
use nested inner
if (which git | is-empty) { error make {msg: "git missing"} }
let closure_with_captured = {|| $counter }
let sorted = [3 1 2] | sort-by {|x| -($x) }
let grouped = [1 2 3 4] | group-by {|x| $x mod 2 }
let reduced = [1 2 3] | reduce {|it, acc| $acc + $it }
let folded = 1..5 | reduce --fold 10 {|it, acc| $acc * $it }
let windowed = [1 2 3 4] | window 2 | each {|w| $w | math sum }
let zipped = [1 2] | zip [3 4]
let ranged_each = 1..3 | each {|i| $i ** 2 }
let match_range = match 5 { 1..3 => "low", 4..6 => "mid", _ => "high" }
let match_str = match "abc" { "abc" | "def" => 1, $s if ($s | str length) > 3 => 2, _ => 0 }
let match_rec = match {a: 1, b: 2} { {a: $x, b: $y} => ($x + $y), _ => 0 }
let match_list = match [1 2 3] { [$h, ..$t] => $h, [] => 0 }
let match_null = match null { null => "nothing", _ => "something" }
let ternary = if $flag { 1 } else { 2 }
let nested_interp = $"outer ($"inner (1 + 1)")"
let ansi_str = $"(ansi red)red(ansi reset)"
let char_str = $"a(char tab)b(char nl)(char -u '1F4E6')"
print --no-newline "no newline"
print -e "to stderr"
input "prompt: " | str trim
exit 0

# ── Jobs, generators, plugins and other recent commands ──
plugin use gstat
let job_id = job spawn { sleep 1sec; print "background" }
job send $job_id "message"
job recv --timeout 1sec
job list | where type == frozen
job kill $job_id
let fib = generate {|state = {a: 0, b: 1}| {out: $state.a, next: {a: $state.b, b: ($state.a + $state.b)}} } | first 10
let counted = 1.. | each while {|i| if $i < 5 { $i } }
let formatted = {name: "x", n: 2} | format pattern "{name}-{n}"
let converted = "5" | into value
let tmp = mktemp --directory
exec echo replaced
if (is-terminal --stdin) { print "interactive" }
input list --fuzzy ["a" "b" "c"]
watch . --glob=**/*.rs {|op, path, new_path| print $"($op) ($path)" }
const compile_time = (1 + 2)
const names = [alpha beta]
export const DEFAULTS = {retries: 3, timeout: 5sec}
def "str shout" []: string -> string { $in | str upcase | $"($in)!" }
def --env --wrapped wrap [...args: string] { ^env ...$args }
alias gs = git status
alias "my alias" = echo aliased
export alias gl = git log --oneline
$env.config = {
    show_banner: false
    history: {max_size: 10_000, file_format: "sqlite"}
    keybindings: [{name: reload, modifier: control, keycode: char_r, mode: emacs, event: {send: executehostcommand, cmd: "exec nu"}}]
    hooks: {pre_prompt: [{|| null }], env_change: {PWD: [{|before, after| print $after }]}}
}
$env.PATH = ($env.PATH | split row (char esep) | prepend "/opt/bin" | uniq)
$env.ENV_CONVERSIONS = {PATH: {from_string: {|s| $s | split row (char esep) }, to_string: {|v| $v | str join (char esep) }}}
$env.PROMPT_COMMAND = {|| $"(pwd | path basename)> " }
let regex_split = "a1b2" | split row --regex '\d'
let parsed = "k=v" | parse "{key}={value}"
let rows = ls | each {|f| {name: $f.name, kb: ($f.size / 1kb)} }
let first_col = $rows | get 0.name
let optional_col = $rows | get -i 99.name
let deep_update = {a: {b: [1 2]}} | update a.b.0 99
let merged_rec = {a: 1} | merge {b: 2} | merge deep {c: {d: 3}}
let spread_args = [1 2] | each {|x| [...$list_commas $x] }
let all_any = [true false] | all {|b| $b }
let optional_chain = {a: null}.a?.b?
# Comments with trailing text # still a comment
# Last line.
