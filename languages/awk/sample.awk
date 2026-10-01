#!/usr/bin/awk -f
# Warehouse stock report: reads "sku qty price category" lines, prints totals.
# Usage: awk -f sample.awk -v threshold=25 stock.txt
# TODO: support quoted fields.

# ── Pattern-action rules ──────────────────────────────────────────────
BEGIN {
    FS = "[ \t]+"
    OFS = "\t"
    ORS = "\n"
    RS = "\n"
    CONVFMT = "%.6g"
    OFMT = "%.2f"
    SUBSEP = ":"
    if (threshold == "") threshold = 25
    print "sku", "qty", "value"
    # numeric literals: integer, float, exponent, hex-looking-as-string, octal-ish
    n_int = 42; n_flt = 3.14159; n_exp = 1.5e-3; n_big = 1E10; n_neg = -7
    # string literal with escapes
    msg = "tab:\t newline:\n quote:\" slash:\\ bell:\a octal:\101 hex:\x41 unicode: é"
    # regex literals and dynamic regex strings
    re_sku = "^[A-Z]-[0-9]{3}$"
    version = "1.2.3"
}

# Comment-only line patterns
/^#/ { next }
/^$/ { next }

# Regex pattern, string comparison, and boolean combinations
$1 ~ /^[A-Z]-[0-9]+$/ && $2 > 0 {
    qty[$1] += $2
    value[$1] += $2 * $3
    cat[$4]++
    seen[$1, $4] = 1                      # multi-dimensional key via SUBSEP
    total += $2 * $3
    count++
}

$2 < threshold && $2 !~ /^0+$/ { low[$1] = $2 }

NR == 1, NR == 3 { header_lines++ }       # range pattern
NR % 2 == 0 { even++ }
$NF == "fragile" || /heavy/ { special++ }
!($1 in qty) { unknown++ }
length($0) > 80 { long_lines++ }

# Ternary, increment/decrement, compound assignment, exponent
{
    bytes += length($0) + 1
    avg = count ? total / count : 0
    sq = $2 ^ 2
    sq2 = $2 ** 2
    n = n + 1; n++; ++n; n--; --n
    n += 1; n -= 1; n *= 2; n /= 2; n %= 7; n ^= 2
    neg = -n; pos = +n; inv = !n
    cmp = (n <= 3) + (n >= 3) + (n != 3) + (n == 3)
    cat_str = $1 " " $2 " " $3                      # concatenation
    field = $(NF - 1)
    indirect = $($1 ~ /x/ ? 1 : 2)
}

# ── User-defined functions ────────────────────────────────────────────
function human(n,   units, i) {
    split("B KB MB GB TB", units, " ")
    for (i = 1; n >= 1024 && i < 5; i++)
        n /= 1024
    return sprintf("%.1f %s", n, units[i])
}

function max(a, b) {
    return a > b ? a : b
}

function repeat(s, n,   out) {
    while (n-- > 0)
        out = out s
    return out
}

func legacy_name(x) { return x }       # 'func' is an accepted synonym

function walk(arr, key) {
    for (key in arr)
        printf "%s=%s\n", key, arr[key]
}

# ── Control flow ──────────────────────────────────────────────────────
function classify(q) {
    if (q == 0) {
        return "empty"
    } else if (q < 25) {
        return "low"
    } else {
        return "ok"
    }
}

function loops(   i, line, rc) {
    do {
        i++
    } while (i < 3)

    for (i = 0; i < 10; i++) {
        if (i == 2) continue
        if (i > 6) break
    }

    while ((rc = (getline line < "/etc/hostname")) > 0)
        names[++nn] = line
    close("/etc/hostname")

    "date +%Y" | getline year
    close("date +%Y")
    return year
}

# ── Built-in functions ────────────────────────────────────────────────
function builtins(s,   a, parts, k) {
    k = length(s) + index(s, "x") + match(s, /[0-9]+/) + RSTART + RLENGTH
    parts = split(s, a, /,/)
    s2 = substr(s, 2, 3)
    s3 = tolower(toupper(s))
    sub(/a/, "b", s)
    gsub(/[aeiou]/, "<&>", s)
    gsub("x", "\\&", s)
    r = int(3.7) + sqrt(16) + exp(1) + log(10) + sin(0) + cos(0) + atan2(1, 1)
    srand(42); r += rand()
    r += systime()
    out = strftime("%Y-%m-%d", systime())
    printf "%5.2f|%-8s|%05d|%x|%o|%e|%c|%%\n", r, s, 42, 255, 8, 1234.5, 65
    printf("%s %s\n", "paren", "form")
    print "to stderr" > "/dev/stderr"
    print "append" >> "report.log"
    print "pipe" | "sort"
    fflush()
    system("true")
    delete a[1]
    delete a
    return s
}

# ── Special variables ─────────────────────────────────────────────────
{ ln = NR ":" FNR ":" NF ":" FILENAME ":" ENVIRON["HOME"] ":" ARGC ":" ARGV[0] }
FNR == 1 { files++ }

# ── Report ────────────────────────────────────────────────────────────
END {
    for (sku in qty)
        printf "%s\t%d\t%.2f\n", sku, qty[sku], value[sku]
    for (c in cat)
        print c, cat[c]
    for (k in seen) {
        split(k, pair, SUBSEP)
        print pair[1], pair[2]
    }
    if ((("A-100", "tools") in seen) && length(low) > 0)
        print "low stock items:", length(low) > "/dev/stderr"
    print "total value:", human(bytes), max(count, 1), classify(count)
    exit count > 0 ? 0 : 1
}

# ── Further constructs ────────────────────────────────────────────────
# gawk extensions, shown for highlighting; each is syntactically valid.
@include "helpers.awk"
@load "filefuncs"
@namespace "warehouse"

BEGINFILE { if (ERRNO) { nextfile } }
ENDFILE   { files_done++ }

BEGIN {
    PROCINFO["sorted_in"] = "@ind_str_asc"
    IGNORECASE = 1
    FPAT = "([^,]+)|(\"[^\"]+\")"
    FIELDWIDTHS = "3 5 2"
    RT = ""
    BINMODE = 3
    LINT = "fatal"
    TEXTDOMAIN = "warehouse"
    FS = OFS = "\t"
    printf "%s\n", "unterminated-looking: \" ' `"
    n = split("a:b:c", parts, ":", seps)
    asort(parts, sorted)
    asorti(parts, indices, "@val_num_desc")
    result = gensub(/(a)(b)/, "\\2\\1", "g", "abab")
    pos = match("foobar", /o+/, groups)
    t = strftime("%H:%M:%S", mktime("2024 01 02 03 04 05"))
    out = and(5, 3) + or(5, 3) + xor(5, 3) + lshift(1, 4) + rshift(16, 2) + compl(0)
    s = sprintf("%'d %i %5.3s %-*d %c %u", 1234567, 3, "abcdef", 4, 7, 65, 9)
    isarray(parts) && length(parts) > 0
    typeof(n) == "number"
    patsplit("a,b", fields, /[^,]+/)
    strtonum("0x1F") + strtonum("017")
    substr("hello", 2)
    toupper(substr("word", 1, 1)) tolower(substr("WORD", 2))
    "date" | getline today; close("date")
    print "to coprocess" |& "cat"
    "cat" |& getline reply
    close("cat", "to")
    @dynamic_func(1, 2)
    fn = "max"; result = @fn(3, 4)
    switch (n) {
    case 1:
        print "one"
        break
    case /^[0-9]+$/:
        print "number"
        break
    case "str":
        print "string"
        break
    default:
        print "other"
    }
    delete parts
    exit
}

function warehouse::helper(x,   local) {
    return x * 2
}

# Regex features: dynamic regexps, bracket expressions, interval expressions
$0 ~ "^" prefix "[[:alpha:]_][[:alnum:]_]*$" { named++ }
$1 ~ /[[:upper:]][[:lower:]]+/ { cased++ }
$2 ~ /^[+-]?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$/ { numeric++ }
/a\/b/ || /\.\*\+\?\|\(\)\[\]\{\}\^\$/ { escaped++ }
/\y\w+\s\S+\B\<word\>/ { word_boundaries++ }

# Getline forms
function readers(   line, cmd) {
    getline                         # next record into $0
    getline line                    # next record into var
    getline < "file"                # from file into $0
    getline line < "file"           # from file into var
    cmd = "echo hi"
    cmd | getline                   # from command into $0
    cmd | getline line              # from command into var
    close(cmd)
}

# Output redirection and special files
{
    print > "/dev/stdout"
    print $0 > "/dev/stderr"
    print $1, $2 >> "/tmp/out.log"
    print | "sort -u"
    printf("%s\n", $0) | "cat 1>&2"
    print > "/dev/fd/3"
    print "inet" > "/inet/tcp/0/localhost/8080"
    system("")
    fflush("/dev/stdout")
}

# Uninitialised variables, numeric strings, assignments in conditions, semicolon-free rules
NF { fields += NF }
!NF { blanks++ }
END { if (!(blanks)) print "no blanks"; else print blanks "blank lines" }
