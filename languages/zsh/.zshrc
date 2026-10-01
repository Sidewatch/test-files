#!/usr/bin/env zsh
# Zsh 5.9 — syntax showcase
# ── Comments ───────────────────────────────────────────────
# ~/.zshrc — interactive shell setup for a warehouse developer machine.
# TODO: move work aliases to a separate file. FIXME: slow compinit on cold start.
# vim: set ft=zsh sw=2 ts=2 et:

# Profiling hook (uncomment to measure start-up)
# zmodload zsh/zprof

# ── Environment ────────────────────────────────────────────
export EDITOR=vim
export VISUAL="$EDITOR"
export PAGER='less -FRX'
export LANG=en_GB.UTF-8
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
export WAREHOUSE_HOME="${WAREHOUSE_HOME:-$HOME/warehouse}"
typeset -U path fpath manpath
path=("$HOME/bin" $path)
fpath=("$HOME/.zsh/completions" $fpath)
typeset -gx GOPATH="$HOME/go"
typeset -x LESS=-R
readonly APP_NAME="warehouse"
local -r REORDER_POINT=25
integer count=0
float ratio=0.75
declare -A sku_names=(
  [WGT-100]="Widget"
  [GDG-200]="Gadget"
  ["GZM 300"]='Gizmo'
)
typeset -a tags=(small metal 'two words' "$APP_NAME")
declare -i int_var=42 hex_var=16#FF bin_var=2#1010
readonly -a ro_array=(a b c)

# ── Options ────────────────────────────────────────────────
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE EXTENDED_HISTORY
setopt EXTENDED_GLOB NO_CASE_GLOB GLOB_DOTS AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS PROMPT_SUBST CORRECT NO_BEEP
unsetopt FLOW_CONTROL MENU_COMPLETE
setopt noclobber nomatch

# ── History ────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# ── Completion ─────────────────────────────────────────────
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion::complete:*' use-cache on
zstyle -e ':completion:*:hosts' hosts 'reply=( ${${(f)"$(<~/.ssh/known_hosts)"}%%[ ,]*} )'
compdef _git gco=git-checkout
zmodload zsh/complist
zmodload -F zsh/stat b:zstat

# ── Prompt: directory, git branch, status colour ───────────
autoload -Uz vcs_info add-zsh-hook colors && colors
precmd() { vcs_info }
add-zsh-hook preexec _record_start
zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:*' enable git
PROMPT='%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f %(?.%F{green}❯.%F{red}❯)%f '
RPROMPT='%F{240}%*%f %B%n@%m%b %K{red}%S%?%s%k %{$fg[cyan]%}%D{%H:%M}%{$reset_color%} %U%l%u %(!.#.$) %2~ %j%(1j. [%j].)'
PS2='%_> '

# ── Aliases ────────────────────────────────────────────────
alias ll='ls -lah'
alias gs='git status -sb'
alias ..='cd ..'
alias -g L='| less'
alias -g NE='2>/dev/null'
alias -s json=jq
alias -s {md,txt}=$EDITOR
alias grep='grep --color=auto'
unalias run-help 2>/dev/null

# ── Functions ──────────────────────────────────────────────
# A function with a default argument
mkcd() { mkdir -p "${1:?dir}" && cd "$1"; }

function stock_report() {
  emulate -L zsh
  setopt local_options err_return
  local sku="${1:-WGT-100}" qty=${2:-0}
  local -a lines
  local -A seen
  [[ -n $sku && $qty -ge 0 ]] || { print -u2 "bad arguments"; return 1 }
  lines=("${(@f)$(grep -c "$sku" inventory.csv 2>/dev/null)}")
  print -P "%F{green}$sku%f has $qty units"
  printf '%s: %d (%.2f%%)\n' "$sku" "$qty" "$(( qty * 100.0 / 40 ))"
  return 0
}

function precmd_hook precmd_other { print -n "\e]0;${PWD:t}\a" }

chpwd() { ls }
TRAPINT() { print "interrupted"; return $(( 128 + $1 )) }
TRAPEXIT() { print "bye" }

# ── Strings and quoting ────────────────────────────────────
single='single quoted $notExpanded `not run` \n'
double="double $USER ${HOME} $(whoami) `date +%Y` \"escaped\" \$literal \\ backslash"
ansi=$'tab\there\nnewline \x41 \u00e9 \e[1mbold\e[0m \'single\''
heredoc=$(cat <<EOF
Interpolated $USER in a here-document
  total: $(( 2 + 3 ))
EOF
)
literal_heredoc=$(cat <<'EOF'
Not interpolated: $USER $(whoami)
EOF
)
indented_heredoc=$(cat <<-EOT
	tab-indented body
	EOT
)
herestring=$(cat <<< "here-string $APP_NAME")
concat="a"'b'$'c'"${double:0:3}"

# ── Parameter expansion flags and modifiers ────────────────
file=/path/to/archive.tar.gz
print ${file:t} ${file:h} ${file:r} ${file:e} ${file:t:r}
print ${file##*/} ${file%.*} ${file%%.*} ${file#*/} ${file/path/dir} ${file//t/T} ${file/#\//root}
print ${#file} ${file:0:4} ${file: -3} ${file:-default} ${file:=assign} ${file:+alt} ${file:?error}
print ${(U)file} ${(L)file} ${(C)file} ${(s:/:)file} ${(j:,:)tags} ${(o)tags} ${(O)tags} ${(u)tags}
print ${(k)sku_names} ${(v)sku_names} ${(kv)sku_names} ${(@)tags} ${(P)APP_NAME} ${(q)file} ${(Q)file}
print ${(l:10::0:)count} ${(r:10:)APP_NAME} ${(%)PROMPT} ${(e)double} ${(z)double} ${(w)#double}
print ${tags[1]} ${tags[-1]} ${tags[2,3]} ${tags[(i)metal]} ${tags[(r)m*]} ${#tags} ${#tags[@]}
print ${sku_names[WGT-100]} ${(k)sku_names[(I)W*]} ${+sku_names[WGT-100]} ${sku_names[(e)GZM 300]}
print $((count + 1)) $((count++)) $((--count)) $(( 2 ** 10 )) $(( 7 / 2.0 )) $(( 0xFF & 0b1010 | 3 ^ 4 << 1 >> 1 )) $(( ratio * 2 ))
print $(( int_var > 3 ? 1 : 0 )) $(( !count && ~count || count )) $(( count == 0 )) $(( RANDOM % 10 ))
print $[1 + 2]
print ${~glob_var} ${=word_split_var} ${^array_var}x ${==quoted}

# ── Globbing: qualifiers, extended, recursive ──────────────
print *.log(.N) **/*.swift(#q.om[1,5]) *(/) *(@) *(x) *(m-1) *(L+100) *(oL[1]) *(On[1,3]) *(D) *(N)
print ^*.o *.(c|h) *.<1-10> **/*~*/build/*(.) *(#i)README* (#a1)fuzzy *.{c,h,swift}
print /tmp/{a,b,c}.txt file{1..5}.txt file{01..10..2}.txt {a..e}
print -l ~/Documents/*(.om[1,3]:t) ~+/ ~- ~root ~/bin/**/*(#qN.x:t)
print (#s)start (#e)end ?(a|b)#c +(foo|bar) @(x|y) !(skip)

# ── Control flow ───────────────────────────────────────────
if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
elif [[ -d ~/.zsh.d && ! -L ~/.zsh.d ]] || (( $+commands[brew] )); then
  for f in ~/.zsh.d/*.zsh(N); do . $f; done
else
  :
fi

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ $OSTYPE == darwin* ]] && export BROWSER=open || export BROWSER=xdg-open
[[ $sku =~ '^[A-Z]{3}-[0-9]+$' ]] && print "valid: $MATCH ${match[1]}"
[[ -z $x || -n $y || $a == $b || $a != $b || $a < $b || $a > $b ]]
[[ -e f && -r f && -w f && -x f && -s f && -d d && -L l && f1 -nt f2 && f1 -ot f2 && f1 -ef f2 ]]
(( count > 5 && ratio <= 1.0 || count == 0 ))

for i in 1 2 3; do print $i; done
for (( i = 0; i < 3; i++ )); do print $i; done
for key val in ${(kv)sku_names}; do print "$key -> $val"; done
foreach name (a b c)
  print $name
end
while read -r line; do print -r -- "$line"; done < <(ls)
until (( count >= 3 )); do (( count++ )); done
repeat 3 do print again; done
select choice in one two three; do print $choice; break; done

case $OSTYPE in
  darwin*)  alias ls='ls -G' ;;
  linux*|gnu*) alias ls='ls --color=auto' ;;
  (freebsd*) ;|
  (openbsd*) ;&
  *) : ;;
esac

{
  print "try block"
  false
} always {
  print "always runs"
}

# ── Pipes, redirection, process substitution ───────────────
ls -l | grep '^d' | wc -l
ls >out.txt 2>&1
ls &>all.txt
ls >>log.txt 2>>err.txt
ls >| force.txt
ls 2>&- <&-
diff <(sort a.txt) <(sort b.txt) >(cat)
cat <<<"$APP_NAME" | tee >(wc -c) >/dev/null
print foo |& cat
exec 3>&1 4<&0
ls &
coproc cat
disown %1
command -v brew &>/dev/null && eval "$(brew shellenv)"
sleep 1 && echo done || echo failed; echo next
( cd /tmp && ls ) &!
time ls
noglob find . -name *.swift
nocorrect git status
builtin cd -- "$HOME"
command ls

# ── Key bindings and zle widgets ───────────────────────────
bindkey -e
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^R' history-incremental-search-backward
bindkey -M menuselect '^[[Z' reverse-menu-complete
bindkey -s '^o' 'ls -lah\n'
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N my-widget
my-widget() { BUFFER="git status"; zle accept-line }
zle -N zle-line-init
zle -A my-widget alias-widget

# ── Special parameters, anonymous functions, misc builtins ─
print $0 $1 $@ $* $# $? $$ $! $- $_ $argv[1] $status $pipestatus[1] $ZSH_VERSION $ZSH_NAME $ZSH_EVAL_CONTEXT
print $LINENO $SECONDS $RANDOM $EPOCHSECONDS $EPOCHREALTIME $HOST $HOSTNAME $UID $EUID $GID $PWD $OLDPWD $TTY $TTYIDLE
print $funcstack[1] $functrace[1] $funcfiletrace[1] $options[extendedglob] $commands[ls] $aliases[ll] $galiases[L] $parameters[PATH]
print $widgets[self-insert] $dirstack[1] $jobstates[1] $jobtexts[1] $nameddirs[root] $userdirs[root] $modules[zsh/complist]
print $BUFFER $LBUFFER $RBUFFER $CURSOR $KEYS $WIDGET $LASTWIDGET $NUMERIC $PREBUFFER $CONTEXT $HISTNO $MATCH $MBEGIN $MEND $match $mbegin $mend $reply $REPLY
print $words[1] $CURRENT $PREFIX $SUFFIX $IPREFIX $ISUFFIX $compstate[nmatches] $curcontext $PS1 $PS4 $RPS1 $SPROMPT $TMOUT $WATCH $WORDCHARS
() { local anon=1; print "anonymous function $anon $*" } a b
function () { print "keyword anonymous" }
local -n ref=count
typeset -r CONSTANT=1
typeset -g global_from_function=1
typeset -ft traced_func
typeset -m 'sku_*'
typeset +x LESS
export -n LESS
private priv_var=1
trap 'print "got signal"; return' INT TERM HUP
trap - INT
trap 'cleanup' EXIT ZERR DEBUG
ulimit -n 4096
umask 022
limit coredumpsize 0
eval "echo evaluated"
exec true
hash -d wh=$WAREHOUSE_HOME
hash -r
rehash
whence -v ls
where ls
which ls
type -a ls
functions mkcd
autoload -U zmv && zmv -n '(*).txt' '$1.md'
zparseopts -D -E -A opts -- v -verbose f: -file:
zformat -f result '%a %b' a:one b:two
zstat -A stats $file
zcompile ~/.zshrc
vared -p 'name: ' -c name
read -r -k 1 "?Continue? " reply
read -sq "?Password placeholder: " secret
print -rn -- "no newline"
print -z "pushed to buffer"
print -s "added to history"
print -C 2 a b c d
print -lr -- $tags
print -D $PWD
print -f '%s\n' formatted
echo -e "echo escapes\t\x41"
getopts "ab:" opt
shift 1
set -e -u -o pipefail
set +x
set -- positional args
unset count
unfunction mkcd
unhash -d wh
unsetopt err_return
emulate zsh -c 'print emulated'
sched +60 'print scheduled'
bg %1; fg %1; jobs -l; wait; kill -TERM %1
cd -; cd ~wh; pushd /tmp; popd; dirs -v
fc -l -10
history -E 1
r
!!
!$
!-2
!?foo?
^old^new
alias -m 'g*'
local IFS=$'\n\t'
break; continue

# ── Additions: modules, array and assoc forms, tests ───────
zmodload zsh/mathfunc zsh/datetime zsh/files zsh/parameter zsh/zutil zsh/pcre
typeset -T COLON_LIST colon_list ':'
typeset -aU unique_list
unique_list+=(one two one)
sku_names+=(WGT-300 "Wrench")
sku_names[extra]=value
nums=(5 3 9 1)
print ${(on)nums} ${(On)nums} ${nums:#3} ${(M)nums:#<4->} ${nums[(r)9]} ${nums[(Ie)9]} ${(j:+:)nums}
print ${(f)"$(<file.txt)"} ${(ps:\n:)raw} ${(@)${(f)text}[2,-1]} ${(Z:Cn:)line} ${~${(j:|:)tags}}
print ${${(%):-%x}:A:h} ${(%):-%N} ${(S)file#*/} ${(I:2:)file//a/b} ${(*)glob_var}
print $(( sqrt(16) + sin(0) + floor(2.5) + abs(-3) )) $(( rand48() )) $(strftime '%Y-%m-%d' $EPOCHSECONDS)
[[ -v tags ]] && [[ -o extendedglob ]] && [[ ! -t 1 ]] && [[ $file -ef $file ]]
[[ abc == a(b|c)# ]] && [[ $sku -pcre-match '^[A-Z]+' ]]
[[ ${(t)tags} == *array* && ${(t)sku_names} == *association* ]]
(( ${#tags} > 1 )) && (( ratio < 1 )) || print "limits"
coproc { while read -r line; do print "got $line"; done }
print -p "message" && read -p reply_line
function named_widget() {
  local -a args=("$@")
  local -A opts
  zparseopts -D -E -A opts -- h -help v:: -verbose=v
  : ${opts[-v]:=default}
  print -- "${(@)args}" "${(kv)opts}"
}
name=value cmd_with_env_prefix --flag
{ print one; print two } > combined.txt
print one && { print two; print three } || print four
for (( i = 0, j = 10; i < j; i++, j-- )) print $i $j
for f in *(N); do :; done
if [[ -e /nonexistent ]] { print yes } else { print no }
() { print "anonymous with args: $@" } 1 2 3
alias -g G='| grep -i'
alias -s py=python3
print ${${(M)path:#*bin*}[1]} ${#${(f)"$(ls)"}}

# ── Plugins and tools ──────────────────────────────────────
source "${ZDOTDIR:-$HOME}/.zsh/plugins/syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null
eval "$(fzf --zsh 2>/dev/null)"
eval "$(starship init zsh)"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
(( $+functions[zprof] )) && zprof
return 0
