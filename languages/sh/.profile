# POSIX sh (POSIX.1-2024, Issue 8) — syntax showcase
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
next=$((count > 0 ? count : -count))
next=$((~next + !next + (next >= 0) + (next && 1) + (next || 0)))
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

# -a / -o inside [ ] are obsolescent (deprecated) but still valid
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

# ── Further tests (all POSIX test operators) ──
[ -b /dev/null ] || [ -c /dev/null ] || [ -p /dev/null ] || [ -S /dev/null ] || :
[ -g /tmp ] || [ -u /bin/su ] || [ -k /tmp ] || [ -r /etc/passwd ] || [ -t 0 ] || :
[ "$count" -eq 1 ] || [ "$count" -ne 1 ] || [ "$count" -gt 1 ] || [ "$count" -lt 1 ] || [ "$count" -le 1 ]
[ "a" \> "b" ] || [ "a" = "a" ] || [ ! -z "x" ] || [ "x" ]
[ \( -f /etc/passwd -o -d /etc \) -a ! -e /nope ] || :
test "$count" -ge 0 && test -n "$today"

# ── Shell options ──
set -f
set +f
set -C
set +C
set -a
set +a
set -o noclobber
set +o noclobber
set -o pipefail 2>/dev/null || :
set -o | head -n 1 >/dev/null
set -o errexit
set +o errexit
(set -x; : traced)
(set -v; : verbose)
(set -n; : not executed)

# ── More quoting and expansion ──
dollar_single=$'tab\there\nnewline \x41 \101 \u00e9 \\ \e[0m'  # POSIX.1-2024 dollar-single-quotes
tilde_paths=~/bin:~root/lib:~+/here:~-/there
IFS_save=$IFS
IFS=:
set -- $PATH
IFS=$IFS_save
IFS=' ' read -r first rest <<EOF3
alpha beta gamma
EOF3
printf '%s|%s\n' "$first" "$rest"
printf '%b\n' 'a\tb' 'c\0101'
printf '%5.2f|%-8s|%+d|%x|%o|%c|%%\n' 3.14159 text 5 255 8 Z
echo "${1-default}" "${1:-default}" "${1=}" "${1:=x}" 2>/dev/null
echo "${@}" "${*}" "${#}" "${#@}" "${?}"
echo "$((1 + 2))" "$(( 0x10 + 010 ))" "$((count = 5))" "$((count += 2))" "$((count <<= 1))"
x=$((count > 3 ? 1 : 2)) y=$(( (1, 2) )) 2>/dev/null || :

# ── More here-documents and redirections ──
cat <<"QUOTED"
No $expansion in double-quoted delimiter either.
QUOTED
cat <<\ESCAPED
Backslash-escaped delimiter: no $expansion.
ESCAPED
cat <<A; cat <<B
first $HOME
A
second $USER
B
echo "$(cat <<IN_SUBST
inside command substitution
IN_SUBST
)"
exec 5<>/tmp/rw.txt
echo rw >&5
exec 5>&-
cat <&0 2>&1 1>/dev/null </dev/null
{ echo a; echo b; } >/tmp/group.txt 2>&1
( echo sub ) | cat
echo err >&2 2>/dev/null
cmd_out=$(ls /nope 2>&1 >/dev/null || echo failed)

# ── Pipelines, compound commands, loops ──
! grep -q nothing /etc/passwd && echo "negated pipeline"
printf '%s\n' b a c | sort | while read -r line; do printf 'line=%s\n' "$line"; done
while IFS= read -r l; do :; done </etc/hostname
for file in *.nothing; do [ -e "$file" ] || continue; done
for i in 1 2 3; do
    for j in a b; do
        [ "$j" = b ] && continue 2
        [ "$i" = 3 ] && break 2
    done
done
if true; then :; fi
if ! false; then :; elif true; then :; else :; fi
while :; do break; done
until false; do break; done
case "$today" in (2*) echo year ;; (*) echo none ;; esac
case $count in 1|2|3) : ;; esac
case x in x) ;; esac

# ── Functions, again ──
greet() { printf 'hello %s\n' "${1:-world}"; }
greet_group() { greet "$@"; } >/dev/null
greet_sub() ( greet "$@" )
greet_if() if [ $# -gt 0 ]; then greet "$1"; fi
recurse() { [ "$1" -le 0 ] && return 0; recurse $(($1 - 1)); }
get_status() { return 3; }
get_status; echo "status $?"
unset -f greet_if
unset -v first rest

# ── Job control, signals and more builtins ──
sleep 1 & pid=$!
kill -s TERM "$pid" 2>/dev/null
kill -0 "$pid" 2>/dev/null
wait "$pid" 2>/dev/null
jobs 2>/dev/null
trap 'echo int' INT TERM HUP
trap '' PIPE
trap 'cleanup_done=1' 0
trap -p >/dev/null 2>&1 || :
umask -S >/dev/null
command -p ls / >/dev/null
command -V ls >/dev/null
hash -r 2>/dev/null
cd -P -- /tmp && cd -L -- "$HOME" && cd - >/dev/null
alias gs='git status' lsa='ls -a'
unalias gs lsa
readonly -p >/dev/null
export -p >/dev/null
type greet >/dev/null
fc -l -1 2>/dev/null
break_demo() { for _ in 1; do break; done; }
exit_demo() { (exit 3); echo "subshell exit $?"; }
. /dev/null
eval 'echo "eval $0"'
exec 2>&2

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
ls ~/*.txt [a-c]?.log [!a-c]* [^x]* [[:alpha:]]*.[[:digit:]] 2>/dev/null
echo ~ ~root

: end of file
