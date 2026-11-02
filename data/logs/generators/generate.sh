#!/bin/bash
#
# Regenerates every log fixture in data/logs, each beside its answer file.
#
#   generators/generate.sh [output-folder]      (default: data/logs itself)
#
# Each toolchain folder is copied into a scratch folder, its pinned dependencies are installed there, and its
# programs write their logs and answers into <scratch>/out/<format>/. finalize.py then rewrites the scratch
# paths, checks every answer file against its log and copies the result into the output folder.
#
# Needs: python3, node + npm, php + composer, ruby, cargo, swiftc, curl, /usr/sbin/httpd and /usr/bin/log
# (macOS). Port 18080 on the loopback interface must be free. Takes about two minutes.
#
# Files made from the real clock (structlog, Rust, PHP's error_log, Apache, macOS) get new times and process
# IDs on every run; the rest come out byte for byte the same.

set -euo pipefail
export TZ=UTC LC_ALL=C

HERE=$(cd "$(dirname "$0")" && pwd -P)
DEST=$(cd "${1:-$HERE/..}" && pwd -P)
WORK=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/log-fixtures.XXXXXX")" && pwd -P)
OUT=$WORK/out
trap 'rm -rf "$WORK"' EXIT

for tool in python3 node npm php composer ruby cargo swiftc curl /usr/sbin/httpd /usr/bin/log; do
    command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 1; }
done

cp -R "$HERE"/{documented,python,node,php,ruby,rust,apache,macos} "$WORK"/
mkdir -p "$OUT"/{python,plain,node,logfmt,php,syslog,ruby,rails,rust,apache,macos}

step() { printf '\n== %s\n' "$*"; }

# The real-clock programs stop rather than write an answer whose time could be off by a tick (exit 2); on a
# busy machine that happens now and then, so they get a few tries.
retry() {
    local try
    for try in 1 2 3 4 5; do
        "$@" && return 0
        [ $? -eq 2 ] || return 1
        echo "  (try $try crossed a tick; again)"
    done
    return 1
}
rust_fixture() { "$WORK/rust/target/release/logfixture" "$1" "$OUT/rust/$2.log" "$3" > "$OUT/rust/$2.expected.json"; }

step "Formats written to their documentation"
python3 -I "$WORK/documented/documented.py" "$OUT"

step "Python: logging and structlog"
python3 -m venv "$WORK/python/venv"
"$WORK/python/venv/bin/pip" install --quiet --disable-pip-version-check -r "$WORK/python/requirements.txt"
"$WORK/python/venv/bin/python" -I "$WORK/python/stdlib_logging.py" "$OUT"
"$WORK/python/venv/bin/python" -I "$WORK/python/structlog_json.py" "$OUT/python"

step "Node: pino, bunyan, winston and logfmt"
(cd "$WORK/node" && npm ci --silent --no-audit --no-fund)
node "$WORK/node/json_loggers.js" "$OUT/node"
node "$WORK/node/logfmt.js" "$OUT/logfmt"

step "PHP: error_log, Monolog (Laravel) and Monolog's syslog handler"
(cd "$WORK/php" && composer install --quiet --no-interaction)
retry php "$WORK/php/error_log.php" "$OUT/php"
php "$WORK/php/laravel.php" "$OUT/php"
php "$WORK/php/syslog.php" "$OUT/syslog"

step "Ruby: Logger and a Rails production log"
ruby "$WORK/ruby/logger.rb" "$OUT/ruby"
ruby "$WORK/ruby/rails.rb" "$OUT/rails"

step "Rust: env_logger and tracing"
(cd "$WORK/rust" && cargo build --quiet --release --locked)
retry rust_fixture env env_logger 60
retry rust_fixture tracing tracing 80

step "Apache httpd"
"$WORK/apache/run.sh" "$WORK/apache"
python3 -I "$WORK/apache/answers.py" "$WORK/apache" "$OUT/apache"

step "macOS unified log"
"$WORK/macos/run.sh" "$WORK/macos"
python3 -I "$WORK/macos/answers.py" "$WORK/macos" "$OUT/macos"

step "Scrub, check and copy into $DEST"
python3 -I "$HERE/finalize.py" "$WORK" "$DEST"
