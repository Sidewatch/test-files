# ~/.profile — login shell setup for the warehouse tools (POSIX sh).
# Sourced by sh, dash, ksh, and bash -l.
# TODO: move the host-specific bits into ~/.profile.local
# FIXME: PS1 breaks on very narrow terminals

# shellcheck shell=sh
# shellcheck disable=SC2034

# ── Basics ──
umask 022
set -u
set +e

# ── Variables and export ──
PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export PATH

export EDITOR=vim
export LANG=en_GB.UTF-8
export LESS='-R -F -X'
export WAREHOUSE_REGION="eu-west" WAREHOUSE_TIER=standard
readonly REORDER_POINT=25
unset OLD_PATH 2>/dev/null
INVENTORY_HOME=${INVENTORY_HOME:-/opt/inventory}

# ── Parameter expansion ──
: "${CACHE_DIR:=$HOME/.cache/inventory}"
echo "${INVENTORY_HOME}" "${CACHE_DIR:-/tmp}" "${MISSING:+set}" "${MISSING-unset}"
echo "${#INVENTORY_HOME}" "${INVENTORY_HOME#/opt/}" "${INVENTORY_HOME##*/}"
echo "${INVENTORY_HOME%/inventory}" "${INVENTORY_HOME%%/*}" "${MISSING:?must be set}" 2>/dev/null
echo "$0" "$1" "$#" "$@" "$*" "$?" "$$" "$!" "$-" "${10}"

# ── Quoting ──
single='literal $HOME and `backticks` and "double"'
double="home is $HOME and a quote \" and a dollar \$ and a backslash \\"
ansi_free="line one
line two (a literal newline inside quotes)"
mixed="prefix-"'middle'"-suffix"
escaped=hello\ world
glob_free='*.txt'

# ── Command substitution and arithmetic ──
today=$(date +%Y-%m-%d)
legacy=`uname -s`
nested="$(echo "$(basename "$PWD")")"
count=$((3 + 4 * 2))
count=$((count % 5 - 1))
count=$(( (count << 2) | 1 & 0xff ^ 07 ))
next=$((count++ + 0)) 2>/dev/null || next=0
[ "$count" -ge 0 ] && echo "count=$count"

# ── Here-documents ──
cat <<EOF
Region: $WAREHOUSE_REGION
Today:  $(date)
Escaped: \$NOT_EXPANDED
EOF

cat <<'RAW'
No $expansion here, nor `commands`, nor \escapes.
RAW

cat <<-INDENTED
	Tabs stripped from the start of each line.
	Still expands: $HOME
	INDENTED

# ── Redirections and pipes ──
ls -l /var/lib/inventory > /tmp/listing.txt 2>&1
ls /nonexistent 2>/dev/null
echo appended >> /tmp/listing.txt
sort < /tmp/listing.txt | uniq -c | sort -rn | head -n 3
grep -c . /tmp/listing.txt >&2
exec 3>&1 4<&0
exec 3>&- 4<&-
echo hi >|/tmp/clobber.txt

# ── Lists and operators ──
true && echo "and" || echo "or"
false || echo "fallback"
! false && echo "negated"
sleep 0 &
wait
{ echo "group"; echo "of commands"; }
( cd / && pwd )

# ── Tests ──
if [ -f "$HOME/.profile.local" ]; then
    . "$HOME/.profile.local"
elif [ -d "$HOME/.profile.d" ]; then
    for f in "$HOME"/.profile.d/*.sh; do
        [ -r "$f" ] && . "$f"
    done
else
    :
fi

if [ -z "$SSH_AUTH_SOCK" ] && command -v ssh-agent >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
fi

if [ -n "$EDITOR" -a -x "$(command -v "$EDITOR")" -o -e /etc/hostname ]; then
    echo "tests: -n -a -x -o -e"
fi

if [ "$count" = 5 ] || [ "$count" != 6 ] || [ "$today" \< "2100" ]; then
    echo "string comparisons"
fi

if [ -L /etc/localtime ] && [ -s /etc/passwd ] && [ -w /tmp ] && [ ! -h /nope ]; then
    echo "file tests: -L -s -w -h"
fi

# ── Loops ──
for sku in alpha beta gamma; do
    printf '%s\n' "$sku"
done

for arg; do
    printf 'arg=%s\n' "$arg"
done

i=0
while [ "$i" -lt 3 ]; do
    i=$((i + 1))
    [ "$i" -eq 2 ] && continue
    printf 'i=%d\n' "$i"
done

until [ "$i" -le 0 ]; do
    i=$((i - 1))
    [ "$i" -eq 1 ] && break
done

# ── case ──
classify() {
    case "$1" in
        [0-9]*)          echo "number" ;;
        a|b|c)           echo "early letter" ;;
        *.txt | *.md)    echo "text file" ;;
        ?)               echo "single char" ;;
        "")              echo "empty" ;;
        *)               echo "other" ;;
    esac
}

# ── Functions ──
prompt_dir() {
    case "$PWD" in
        "$HOME"*) printf '~%s' "${PWD#"$HOME"}" ;;
        *) printf '%s' "$PWD" ;;
    esac
}

stock_report() (
    # subshell body: changes here do not leak
    local_count=0
    for n in "$@"; do
        local_count=$((local_count + n))
    done
    printf 'total %d across %d items\n' "$local_count" "$#"
)

die() { printf 'error: %s\n' "$*" >&2; return 1; }

# ── Builtins ──
cd "$HOME" || return 0
pwd -P
type ls >/dev/null
command -v git >/dev/null 2>&1 || die "git missing"
read -r line <<EOF2
a line to read
EOF2
printf '%s\n' "$line"
trap 'echo bye' EXIT
trap - INT
test -d /tmp
alias ll='ls -lA'
shift 0
getopts "ab:" opt 2>/dev/null
eval "echo evaluated"
exec true
set -- one two three
export -p >/dev/null
umask
ulimit -n 2>/dev/null
wait
times >/dev/null

# ── Prompt ──
PS1='$(prompt_dir) \$ '
PS2='> '
export PS1 PS2

# ── Continuation lines ──
long_command=$(printf '%s ' \
    --flag-one \
    --flag-two \
    --flag-three)

# ── Globbing ──
ls ~/*.txt [a-c]?.log {nothing} 2>/dev/null
echo ~ ~root

: end of file
