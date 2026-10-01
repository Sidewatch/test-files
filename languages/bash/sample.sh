#!/usr/bin/env bash
# Bash 5.3 — syntax showcase
# shellcheck shell=bash disable=SC2034
#
# sample.sh - warehouse stock deploy and report script covering Bash syntax.
# TODO: split the report functions into a sourced library.
# FIXME: the retry loop ignores SIGTERM during sleep.

set -euo pipefail
shopt -s nullglob globstar extglob
IFS=$'\n\t'
trap 'cleanup $?' EXIT
trap 'echo "interrupted" >&2; exit 130' INT TERM

# ── Variables and constants ──────────────────────────────────────────
readonly MAX_RETRIES=5
declare -r APP_NAME="stock-portal"
declare -i attempt=0 limit=3
declare -x EXPORTED_VAR="visible to children"
export WAREHOUSE_HOME="${WAREHOUSE_HOME:-/srv/warehouse}"
DEFAULT_TIMEOUT=30
LOG_PREFIX="[deploy]"
local_var=plain
empty=
unset empty

# ── Arrays ───────────────────────────────────────────────────────────
declare -a targets=("web" "api" "worker")
declare -A prices=([widget]=4.50 [gadget]=1.25 ["big thing"]=99)
numbers=(1 2 3 4 5)
numbers+=(6)
targets[3]="batch"
echo "${targets[@]}" "${#targets[@]}" "${!targets[@]}" "${targets[*]:1:2}"
echo "${prices[widget]}" "${!prices[@]}"

# ── Quoting, expansion and substitution ──────────────────────────────
single='no $expansion here, \n literal'
double="value: $local_var ${local_var} ${local_var:-default} ${local_var:=assigned}"
ansi=$'tab\there\nnewline \x41 \u00e9 \'quoted\''
locale=$"translatable string"
escaped="dollar \$ backtick \` quote \" backslash \\"
concat="${APP_NAME}-${attempt}"
path="${WAREHOUSE_HOME%/*}" base="${WAREHOUSE_HOME##*/}" ext="${base%%.*}"
upper="${local_var^^}" lower="${local_var,,}" first="${local_var^}"
replaced="${double/value/VALUE}" all_replaced="${double//a/A}"
len="${#double}" slice="${double:2:5}" tail="${double: -3}"
indirect="${!APP_NAME@Q}"
today=$(date +%F)
legacy=`uname -s`
arith=$((attempt * 2 + 3 ** 2 - 10 % 3))
(( attempt++ )) || true
(( attempt += 2, limit <<= 1 ))
brace="file_{a,b,c}.txt {1..5} {01..10..3}"
tilde=~/stock ~root
glob=(*.sh ?(a|b).txt @(x|y)* +([0-9]) !(skip)*)
diff <(sort "$0") <(sort "$0") > /dev/null
printf -v formatted '%05.1f|%-6s|%x|%q' 3.14159 abc 255 "a b"

# ── Heredocs and herestrings ─────────────────────────────────────────
cat <<EOT
Expanded heredoc: $APP_NAME at $today
  Arithmetic: $((1 + 2)) and command: $(echo hi)
EOT

cat <<'EOT'
Quoted heredoc: $APP_NAME stays literal, \n too.
EOT

cat <<-INDENTED
	Tabs stripped here: ${LOG_PREFIX}
	INDENTED

grep -c "stock" <<< "herestring with $APP_NAME"

# ── Functions ────────────────────────────────────────────────────────
retry_command() {
    local attempt=1
    local -i limit="$MAX_RETRIES"
    local message="starting"

    while (( attempt <= limit )); do
        echo "${LOG_PREFIX} attempt ${attempt} of ${limit}: ${message}"
        if "$@"; then
            return 0
        fi
        (( attempt++ ))
        sleep "$DEFAULT_TIMEOUT"
    done

    printf 'Failed after %d attempts\n' "$limit" >&2
    return 1
}

function classify_status {
    local code="${1:-0}"
    case "$code" in
        0)       echo "ok" ;;
        1|2)     echo "warning" ;;
        [3-9])   echo "error" ;;
        +([0-9])) echo "fatal" ;&
        *)       echo "unknown" ;;
    esac
}

cleanup() {
    local status="${1:-0}"
    rm -f -- "${tmpfile:-}"
    return "$status"
}

# ── Conditionals ─────────────────────────────────────────────────────
if [[ -f "$0" && ! -d "$0" ]] && [ -r "$0" -o -w "$0" ]; then
    echo "script is a readable file"
elif [[ "$APP_NAME" == stock-* || "$APP_NAME" =~ ^[a-z]+$ ]]; then
    echo "pattern match"
else
    echo "neither"
fi

[[ -z "${empty:-}" ]] && echo "empty is unset" || echo "empty is set"
[[ $attempt -ge 1 && $attempt -lt 10 ]] && echo "in range"
[[ "a" < "b" && 3 -eq 3 && 4 -ne 5 && 1 -le 2 && ! -e /nonexistent ]] && echo "tests ok"
test -n "$APP_NAME" && echo "non-empty"
(( attempt > 0 )) && echo "positive"

# ── Loops ────────────────────────────────────────────────────────────
for target in "${targets[@]}"; do
    retry_command echo "Deploying ${target}"
    classify_status "$?"
done

for (( i = 0; i < 3; i++ )); do
    [[ $i -eq 1 ]] && continue
    echo "i=$i"
done

for file in **/*.sh; do
    echo "found $file"
    break
done

n=0
while read -r line; do
    n=$((n + 1))
done < <(printf '%s\n' a b c)

until (( n == 0 )); do
    (( n-- ))
done

select choice in start stop restart; do
    echo "chose $choice"
    break
done < /dev/null

# ── Pipelines, redirection, control operators ────────────────────────
ls -la | grep -v '^total' | sort -k5 -n | head -n 3 | tee /tmp/out.txt > /dev/null
command_one && command_two || command_three &
wait $!
cat < "$0" >/dev/null 2>&1
echo "to stderr" >&2
echo "both" &>/dev/null
exec 3>&1 4<&0
exec 3>&- 4<&-
echo hi >| clobber.txt
{ echo one; echo two; } | wc -l
( cd / && pwd )
time sleep 0.01
coproc BG { cat; }
nohup sleep 1 &>/dev/null & disown

# ── Builtins ─────────────────────────────────────────────────────────
cd "$WAREHOUSE_HOME" || exit 1
pushd /tmp >/dev/null; popd >/dev/null
read -r -p "Continue? " reply || true
source ./lib.sh 2>/dev/null || . ./lib.sh 2>/dev/null || true
eval "echo evaluated"
alias ll='ls -l'
type -t retry_command
hash -r
getopts ":ab:" opt || true
mapfile -t lines < <(echo one; echo two)
readarray -t more <<< "x"
let "z = 1 + 2"
local_status=$?
printf '%s\n' "${PIPESTATUS[@]}" "$BASH_VERSION" "$LINENO" "$RANDOM" "$$" "$!" "$#" "$@" "$*" "$0" "$1" "${10}"

# ── Main ─────────────────────────────────────────────────────────────
main() {
    declare -a args=("$@")
    local tmpfile
    tmpfile="$(mktemp)"
    trap 'rm -f "$tmpfile"' RETURN

    case "${1:-}" in
        -h|--help)
            echo "usage: $0 [-h]"
            exit 0
            ;;
        --version)
            echo "1.0.0"
            ;;
    esac

    echo "Processing ${#args[@]} arguments"
    return 0
}

main "$@"
exit 0

# ── Further constructs ───────────────────────────────────────────────
# Parameter expansion in full
: "${undefined:?must be set}" "${undefined2:+alternate}" "${undefined3-unset_default}"
echo "${var@U}" "${var@L}" "${var@u}" "${var@E}" "${var@P}" "${var@A}" "${var@a}" "${var@K}" "${var@k}"
echo "${!prefix*}" "${!prefix@}" "${array[@]:1}" "${array[-1]}" "${#array[0]}" "${array[@]/a/b}"
echo "${var#prefix}" "${var%suffix}" "${var/#front/F}" "${var/%back/B}" "${var:-${nested:-deep}}"
echo "${var:0:1}" "${@:2}" "${*:1:2}" "$((${#var} * 2))" "${var^^[aeiou]}" "${var,,[AEIOU]}" "${var~}" "${var~~}"

# Special parameters and variables
echo "$_" "$-" "$?" "$$" "$!" "$0" "$@" "$*" "$#" "$1$2$3" "${10}" "$BASH_SOURCE" "${FUNCNAME[0]}" "${BASH_REMATCH[1]}"
echo "$UID $EUID $PPID $PWD $OLDPWD $SHLVL $SECONDS $REPLY $OPTIND $OPTARG $HOSTNAME $OSTYPE $MACHTYPE"
echo "${COMP_WORDS[@]} ${COMPREPLY[@]} ${DIRSTACK[@]} ${GROUPS[@]} ${BASH_ARGV[@]} ${BASH_VERSINFO[0]}"

# Arithmetic forms
(( x = 3, y = x ** 2, z = x > y ? x : y ))
echo $(( 0x1F + 077 + 2#101 + 16#ff + 36#zz ))
echo $(( x++ + ++x - x-- - --x ))
echo $(( ~x & y | z ^ x << 2 >> 1 ))
echo $(( !x || (y && z) ))
echo $[ 1 + 2 ]
let a=1 b=2 'c = a + b'

# Test operators
[ -a f ] ; [ -b f ] ; [ -c f ] ; [ -d f ] ; [ -e f ] ; [ -f f ] ; [ -g f ] ; [ -h f ] ; [ -k f ]
[ -p f ] ; [ -r f ] ; [ -s f ] ; [ -t 1 ] ; [ -u f ] ; [ -w f ] ; [ -x f ] ; [ -G f ] ; [ -L f ]
[ -N f ] ; [ -O f ] ; [ -S f ] ; [ f1 -nt f2 ] ; [ f1 -ot f2 ] ; [ f1 -ef f2 ]
[ -o noclobber ] ; [ -v var ] ; [ -R nameref ] ; [ -n str ] ; [ -z str ]
[[ $a == "$b" && $a != $c ]] ; [[ $a = b* ]] ; [[ ( $a -lt 1 ) || ! ( $b -gt 2 ) ]]
[[ $s =~ ^([a-z]+)-([0-9]+)$ ]] && echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"

# Compound commands, grouping and subshells
{
    echo "in group"
} > /dev/null
( set -e; echo "in subshell" )
if true; then :; fi
for i in 1 2 3; do echo $i; done
while :; do break; done
case $x in a) ;; b) ;& c) ;;& *) esac
function fn_keyword_style() { echo style; }
fn-with-dashes() { echo dashes; }
ns::func() { echo namespaced; }
fn_alt () ( echo "subshell body" )
declare -f fn_alt
declare -F
declare -n ref=target
declare -l lowercase="ABC"
declare -u uppercase="abc"
declare -t traced=1
local -a localarr=()
typeset -g global_from_func=1
export -n unexported
readonly -f fn_alt
unset -v var; unset -f fn_alt

# Redirections of every kind
cmd > out 2> err
cmd >> out 2>> err
cmd &> both
cmd &>> both
cmd 2>&1
cmd 1>&2
cmd < in
cmd <> rw
cmd >&- <&-
cmd 3< in 4> out
cmd {fd}> out
cmd |& other
cmd <<< "here"
cmd <<-'X'
	tab-indented quoted heredoc: $literal
	X
exec {logfd}> >(tee log.txt)
read -ru "$logfd" line

# Process and command substitution, backgrounding, job control
diff <(sort a) <(sort b)
tee >(gzip > out.gz) < in > /dev/null
echo $(echo $(echo nested))
echo `echo \`echo nested\``
sleep 100 & pid=$!
jobs -l; fg %1; bg %2; kill -TERM "$pid" || kill -9 -- -"$pid"
wait -n
disown -h %1
trap - EXIT
trap '' SIGPIPE
trap -l
ulimit -n 1024
umask 022
times
enable -n echo
builtin cd /
command -v ls
exec -a customname bash -c 'echo $0'
set -o pipefail; set +o noclobber; set -- a b c; set -x; set +x
shopt -s extglob; shopt -u dotglob; shopt -q nullglob
bind '"\C-l": clear-screen'
complete -F _my_completion mycmd
compgen -W "start stop" -- "$cur"

# Quoting oddities
echo 'it'\''s' "say \"hi\"" $'\e[1mbold\e[0m' $'☃' $'\U0001F600' $'\cA' $'\0'
echo \$notvar \` \\ \' \" \  \#hash
echo "multi
line string"
echo a\
b
echo ~user ~+ ~- ~root/bin
echo {a..e} {1..10..2} {a,b{c,d}} pre{x,y}post
echo *.sh ./**/*.md [a-c]* ?ile [[:digit:]]*
echo !(*.sh) ?(a) *(b) +(c) @(d|e)
echo $'a\tb' | cat -A
: ${DEBUG:=0}
true && false || echo "fallback"; true & false | cat; ! false
(( $# )) || usage
[ -t 0 ] || exec < /dev/null

# ── Arithmetic assignment and comparison operators ───────────────────
(( x += 1, x -= 1, x *= 2, x /= 2, x %= 7, x **= 2 ))
(( x <<= 1, x >>= 1, x &= 0xFF, x |= 1, x ^= 3 ))
(( x >= 1 && x <= 9 && x != 4 && x == 4 ))
echo $(( 10 >= 5 )) $(( 2 ** 10 )) $(( x = y = 3 ))

# ── Brace expansion, numeric and lettered ranges ─────────────────────
echo {1..10} {10..1} {a..z} {01..05} {1..20..5} {A..C}{1..2}
mkdir -p proj/{src,test}/{unit,integration}

# ── Legacy test operators, combined with -a / -o ─────────────────────
[ -f "$0" -a -r "$0" ] && echo "file and readable"
[ ! -d "$0" -o -w "$0" ] && echo "not a dir or writable"
test -e "$0" -a -s "$0" -o -z "$APP_NAME"

# ── Backtick edge forms ──────────────────────────────────────────────
echo `` `date` "$`date`"

# ── Bash 5.x features ────────────────────────────────────────────────
# Command substitution without a subshell (5.3): funsub and valsub
text=${ echo "no subshell"; }
count=${| REPLY=42; }
echo "${ date +%F; }" "${| REPLY=$((1 + 1)); }"
shopt -s patsub_replacement array_expand_once globskipdots
GLOBSORT="-mtime"
echo "${text//no/& and more}"
echo "$EPOCHSECONDS $EPOCHREALTIME $SRANDOM $BASH_MONOSECONDS ${BASH_ARGV0}"
printf '%(%Y-%m-%d)T\n' -1
printf '%s\n' "${text@Q}" "${text@a}" "${text@A}"
declare -I inherited_var
declare -p text count
local - 2>/dev/null || true
wait -f "$!" 2>/dev/null || true
read -E -p "edit: " editable < /dev/null || true
compgen -V completions -W "alpha beta" -- "a"
[[ -v targets[1] ]] && echo "element set"
typeset -n nameref_var=targets
for item in "${!nameref_var[@]}"; do :; done
name+=" appended"
declare -A map=()
map+=([k]=v)
export -f main
time -p sleep 0
! command -v nonexistent >/dev/null
