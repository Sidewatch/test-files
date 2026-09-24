#!/usr/bin/awk -f
# Summarise an access log: hits and bytes per status code.

BEGIN {
    FS = " "
    print "status", "hits", "bytes"
}

$9 ~ /^[0-9]{3}$/ {
    hits[$9]++
    bytes[$9] += ($10 == "-") ? 0 : $10
    if ($9 >= 500) errors++
}

function human(n,   units, i) {
    split("B KB MB GB", units, " ")
    for (i = 1; n >= 1024 && i < 4; i++) n /= 1024
    return sprintf("%.1f %s", n, units[i])
}

END {
    for (code in hits) printf "%s\t%d\t%s\n", code, hits[code], human(bytes[code])
    if (errors > 0) print "server errors:", errors > "/dev/stderr"
}
