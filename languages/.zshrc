# ~/.zshrc — interactive shell setup.
export EDITOR=vim
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS EXTENDED_GLOB

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# Prompt: directory, git branch, status colour
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f %(?.%F{green}❯.%F{red}❯)%f '

alias ll='ls -lah'
alias gs='git status -sb'

# A function with a default argument
mkcd() { mkdir -p "${1:?dir}" && cd "$1"; }

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
