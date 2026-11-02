#!/bin/bash
#
# Builds main.swift, runs it while `log stream` watches, then reads the same messages back with `log show`.
#
#   run.sh <folder>      leaves <folder>/stream-default.txt, stream.ndjson, show-syslog.txt, show-default.txt
#                        and show.ndjson
#
# Each text capture is a fixture; each .ndjson capture of the same messages is what its answers are made from.
# `log stream` sees Debug messages; `log show` only has what was persisted, which leaves them out.

set -euo pipefail
DIR=$1
cd "$DIR"
swiftc -O -o logfixture main.swift

PREDICATE='subsystem == "com.example.logfixture"'
/usr/bin/log stream --level debug --predicate "$PREDICATE" > stream-default.txt 2>&1 & default_stream=$!
/usr/bin/log stream --level debug --predicate "$PREDICATE" --style ndjson > stream.ndjson 2>&1 & ndjson_stream=$!
sleep 3                                 # let both streams attach before the first message
./logfixture 70 & program=$!
wait $program
sleep 3                                 # let the last messages reach the streams
kill $default_stream $ndjson_stream
wait 2>/dev/null || true

# Only this run's messages: the process ID keeps out earlier runs still in the store.
PREDICATE="$PREDICATE AND processID == $program"
for style in syslog default; do
    /usr/bin/log show --timezone UTC --last 10m --info --debug --predicate "$PREDICATE" --style $style > show-$style.txt
done
/usr/bin/log show --timezone UTC --last 10m --info --debug --predicate "$PREDICATE" --style ndjson > show.ndjson
