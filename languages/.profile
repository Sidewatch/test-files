# ~/.profile — login shell setup (POSIX sh; sourced by sh, dash, ksh, and bash -l).
umask 022

PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export PATH

export EDITOR=vim
export LANG=en_GB.UTF-8
export LESS='-R -F -X'

# Load private settings if present
if [ -f "$HOME/.profile.local" ]; then
    . "$HOME/.profile.local"
fi

# A portable "which directory am I in" for the prompt
prompt_dir() {
    case "$PWD" in
        "$HOME"*) printf '~%s' "${PWD#"$HOME"}" ;;
        *) printf '%s' "$PWD" ;;
    esac
}

PS1='$(prompt_dir) \$ '
export PS1

# Start ssh-agent once per login
if [ -z "$SSH_AUTH_SOCK" ] && command -v ssh-agent >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
fi
