#!/usr/bin/env fish
# fish 4.0 — syntax showcase (fish is not installed locally)
# ── Comments ──
# Line comment. TODO: rotate logs hourly. FIXME: handle spaces in names.
# vim: set ft=fish ts=4 sw=4 et:

# ── Variables: scopes and flags ──
set -l log_dir ~/logs
set -g warehouse_name north
set -gx PATH /opt/warehouse/bin $PATH
set -x EDITOR vim
set -U fish_greeting "Welcome to the warehouse"
set -lx LC_ALL en_GB.UTF-8
set --local keep_days 14
set --global --export STOCK_HOME /opt/warehouse
set -a items "hammer" "bolt"
set -p items "tape"
set -e obsolete_var
set -q log_dir; and echo "log_dir is set"
set bins north south east
set bins[2] west
set bins[1..2] a b
set -l empty

# ── Literals and quoting ──
set -l plain hello
set -l single 'single $quoted \' \\ no expansion'
set -l double "double $plain with \"escapes\" \$ \\ and \n"
set -l unicode "café 日本語 📦 é \x41 \U0001F4E6"
set -l mixed "$plain"'-suffix'"-$warehouse_name"
set -l number 42
set -l negative -17
set -l float 3.14
set -l hexish 0xFF
set -l escapes a\ b\tc\nd\x41é\cI
set -l brace {a,b,c}{1,2}
set -l range (seq 1 5)
set -l home ~
set -l tilde_user ~root/bin
set -l glob *.log
set -l recursive_glob **.log
set -l interp "$bins[1] {$plain}x $bins[2..3] $bins[-1]"
set -l count (count $bins)
set -l cmd_sub (echo (date +%Y-%m-%d))
set -l quoted_sub "result: "(echo hi)

# ── Functions ──
function human --argument-names bytes --description 'Format a byte count'
    if test $bytes -gt 1048576
        printf "%.1f MB" (math $bytes / 1048576)
    else if test $bytes -gt 1024
        printf "%d KB" (math --scale=0 $bytes / 1024)
    else
        printf "%d B" $bytes
    end
end

function fish_prompt --on-event fish_prompt
    set -l last_status $status
    echo -n (set_color cyan)(prompt_pwd)(set_color normal) '> '
end

function on_exit --on-process-exit %self  # %self: deprecated spelling
    echo "bye"
end

function on_var --on-variable warehouse_name
    echo "name changed to $warehouse_name"
end

function on_signal --on-signal SIGINT
    echo interrupted
end

function wrapped --wraps ls --description 'ls with colours'
    command ls --color=auto $argv
end

function greet -a name greeting
    set -q greeting[1]; or set greeting Hello
    echo "$greeting, $name!"
    return 0
end

function argparse_example
    argparse 'h/help' 'n/name=' 'v/verbose' 'c/count=?' -- $argv
    or return
    if set -q _flag_help
        echo "usage"
        return 0
    end
    echo $_flag_name $_flag_count $argv
end

function __private_helper
    status is-interactive; and return 0
    status current-function
    status filename
    status line-number
    return 1
end

# ── Control flow ──
for file in $log_dir/*.log
    set -l age (math (date +%s) - (stat -f %m $file))
    if test $age -gt (math $keep_days \* 86400)
        set -l size (stat -f %z $file)
        echo "removing $file ("(human $size)")"
        rm -- $file; and set removed (math $removed + 1)
    else if test -e $file -a -r $file -o -w $file
        continue
    else
        break
    end
end

set -l n 3
while test $n -gt 0
    set n (math $n - 1)
end

while true
    break
end

switch $removed
    case 0
        echo "nothing older than $keep_days days"
    case 1 2 3
        echo "a few"
    case 'a*' '*.log'
        echo "pattern"
    case '*'
        echo "$removed file(s) removed"
end

begin
    set -l scoped inside
    echo $scoped
end

if test -d $log_dir; and not test -L $log_dir
    echo "directory"
else if test -f $log_dir; or test -z "$log_dir"
    echo "file or empty"
end

# ── Operators, redirection, pipes ──
echo hello | grep -i h | wc -l
echo error >&2
echo out > out.txt 2> err.txt
echo append >> out.txt
command ls 2>&1 | head -n 3
cat < input.txt
echo both &> all.txt
echo clobber >? maybe.txt
echo fd3 3> fd3.txt
cmd1 && cmd2 || cmd3
cmd1; and cmd2; or cmd3
not cmd
command -q git; and echo "git installed"
sleep 10 &
time sleep 1
echo $status $pipestatus $argv $argv[1] $argv[-1] $$ $last_pid $version
echo $fish_pid $USER $HOME $PWD $SHLVL

# ── Builtins and commands ──
math "2 + 3 * 4"
math --scale=2 10 / 3
string match -r '^A-(\d+)$' -- "A-100"
string replace -a ' ' '_' "a b c"
string split ',' "a,b,c"
string join '-' a b c
string trim "  padded  "
string length "stock"
string upper "stock"
string sub -s 2 -l 3 "warehouse"
contains -- north $bins; and echo "found"
test "$plain" = hello; and echo equal
test 5 -lt 10 -a 3 -ge 3
printf '%s\n' $bins
read -l -P "Name: " name
read --prompt-str "> " --silent secret
source ~/.config/fish/conf.d/warehouse.fish
. ./local.fish
eval "echo evaluated"
exec true
abbr -a gs 'git status'
alias ll 'ls -l'
bind \cr history-pager
bind \e\[A up-or-search
complete -c warehouse -s h -l help -d 'Show help'
complete -c warehouse -n '__fish_use_subcommand' -a 'count audit' -x
functions -e old_fn
funcsave greet
emit warehouse_event arg1
fish_add_path /opt/warehouse/bin
status --is-login
jobs
wait
disown
builtin echo "builtin"
command echo "command"
exit 0

# ── fish 4.0 additions ──
abbr -a --position anywhere -- L '| less'
abbr -a --set-cursor gco 'git checkout %'
abbr -a --function _last_history_item !!
abbr --erase gs
set --no-event quiet_var 1
status buildinfo
status get-file functions/fish_prompt.fish
bind --user \cg 'commandline -f cancel'
bind -M insert \cf forward-char
set -l indirect_name bins
echo $$indirect_name[1]
# fish 3.x/4.x: `time` and `not` are keywords; `and`/`or` start a command
not true
true
and echo chained
or echo never

# ── Further constructs ──
# Function options
function inherit_demo --inherit-variable warehouse_name --description 'uses a captured variable'
    echo $warehouse_name
end

function shared_scope --no-scope-shadowing
    set outer_var changed
end

function on_job --on-job-exit %last
    echo job finished
end

function multi_args -a first second third --description "three named args"
    echo $first $second $third
end

function alias_like --wraps='git status' --description 'alias git status'
    git status $argv
end

function __fish_warehouse_complete
    set -l tokens (commandline -opc)
    test (count $tokens) -eq 1
end

function fish_title
    echo (status current-command) (prompt_pwd)
end

function fish_right_prompt
    set_color brblack; date +%H:%M; set_color normal
end

# Command substitution forms (fish 3.4+)
echo $(echo nested $(echo deeper))
set -l files (string split \n -- (ls))
set -l joined (string join ', ' $bins)
set -l first_two $argv[1..2]
set -l from_second $argv[2..-1]
set -l reversed $argv[-1..1]
set -l indexed $bins[(math 1 + 1)]

# Variable expansion edge cases
echo $bins[1]'-'$bins[2]
echo "$bins[1]" "$bins"
echo {$bins}-suffix
echo prefix-{a,b,c}-suffix {1,2,3}
echo \$escaped \"escaped\" \'escaped\' \\ \  \(parens\) \{braces\} \[brackets\] \* \? \# \~ \% \& \; \< \>
echo '*' "*" \*
echo ~/path ~root /tmp/**/*.log ?
echo $fish_pid %self  # %self is deprecated since 3.x, use $fish_pid
echo (string repeat -n 3 =)
echo -n "no newline"; echo -e "escapes\there"; echo -s "squeezed"; echo --
echo foo; echo bar & echo baz

# Redirections and pipes
ls >/dev/null
ls 2>/dev/null >&2
ls &>/dev/null
ls &>> all.log
ls >>log.txt 2>>err.txt
cat <&0
ls 1>&2 2>&1
ls | cat 2>| wc
ls 2>&1 | grep x
ls &| cat
begin; echo a; echo b; end | cat
if true; echo yes; end
for i in 1 2 3; echo $i; end
while false; end
function one_liner; echo hi; end

# Builtins not yet covered
cd -
cd ~/stock; and pwd
pushd /tmp; popd; dirs; prevd; nextd
history search --contains stock
history delete --exact --case-sensitive 'secret command'
commandline -f repaint
commandline --current-token
type -q git; and type -a ls
command -v git
builtin -n
functions --names
functions --details greet
functions -c greet greet2
set --show warehouse_name
set -S bins
set_color --bold --underline brred
set_color -b blue white
set_color normal
random 1 6
random choice a b c
realpath ../stock
path basename /a/b/c.txt
path dirname /a/b/c.txt
path extension /a/b/c.txt
path change-extension .md /a/b/c.txt
path filter -f /etc/hosts
path resolve ~/../tmp
path sort c b a
test -n "$x"; test -z "$x"; test -e /etc; test -d /tmp; test -f /etc/hosts; test -r /etc/hosts; test -w /tmp; test -x /bin/ls; test -s /etc/hosts; test -L /x; test -p /x; test -S /x; test -t 1; test -G /x; test -O /x
test "a" = "a"; test "a" != "b"; test 1 -eq 1; test 1 -ne 2; test 1 -lt 2; test 1 -le 2; test 1 -gt 0; test 1 -ge 0
test ! -e /nope; test \( 1 -eq 1 \) -a \( 2 -eq 2 \) -o 3 -eq 4
[ -f /etc/hosts ] && echo exists
[ "$x" = y ]
isatty stdin
status is-command-substitution
status is-block
status job-control full
status fish-path
status stack-trace
ulimit -n
umask 022
fish_config theme choose Nord
fish_update_completions
fish_vi_key_bindings
fish_default_key_bindings
fish_indent --check
string match --regex --groups-only '(\d+)-(\d+)' -- "10-20"
string match -ai -- 'A*' a b
string escape --style=url 'a b'
string unescape 'a\ b'
string pad -w 8 -c . abc
string collect -- "multi
line"
string lower ABC
string shorten -m 5 'long string'
string sub --start=-3 'warehouse'
string split --max 1 --right / a/b/c
string replace --regex --all '\s+' ' ' -- "a   b"
string match --entire --invert x -- x y z
printf '%s\n%5.2f\n%-8s|\n%03d\n%x\n%c\n%%\n' a 1.5 left 7 255 A
printf '\e[1mbold\e[0m \a \b \f \v \0 \x41 \101 é \U0001F4E6\n'
math "floor(3.7) + ceil(1.2) + round(2.5) + abs(-1) + sqrt(16) + pow(2, 3) + 7 % 3 + max(1, 2) + min(1, 2) + ln(e) + sin(pi / 2) + 0xFF + 1e3"
math --base=hex 255
math -s0 "10 / 3"
sleep 0.1
wait $last_pid
kill -TERM %1
bg; fg
exit 1
