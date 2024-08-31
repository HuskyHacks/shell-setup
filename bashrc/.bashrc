# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History configurations
HISTCONTROL=ignoreboth             # Don't put duplicates or lines starting with space in the history.
shopt -s histappend                # Append to the history file, don't overwrite it.
HISTSIZE=1000                      # Set history size.
HISTFILESIZE=2000                  # Set history file size.

# Shell options
shopt -s checkwinsize              # Update terminal dimensions after each command.

# Prompt configurations
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Set colored prompt if applicable
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Set the terminal title
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
esac

# Enable color support for ls, grep, etc., and define aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'
fi

# Define additional aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias flag='head /dev/urandom | md5sum | cut -d " " -f1 | xargs printf "flag{%s}\n"'
alias dockershell="sudo docker run --rm -i -t --entrypoint=/bin/bash"
alias dockershellsh="sudo docker run --rm -i -t --entrypoint=/bin/sh"

# Docker shell functions
function dockershellhere() {
    dirname=${PWD##*/}
    sudo docker run --rm -it --entrypoint=/bin/bash -v "$(pwd)":/${dirname} -w /${dirname} "$@"
}

function dockershellshhere() {
    dirname=${PWD##*/}
    sudo docker run --rm -it --entrypoint=/bin/sh -v "$(pwd)":/${dirname} -w /${dirname} "$@"
}

# Load .bash_aliases if available
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Less configurations for better appearance
export LESS_TERMCAP_mb=$'\E[1;31m'     # Begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # Begin bold
export LESS_TERMCAP_me=$'\E[0m'        # Reset bold/blink
export LESS_TERMCAP_so=$'\E[01;33m'    # Begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # Reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # Begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # Reset underline

# Export PATH and other environment variables
export PATH=$PATH:/usr/local/go/bin
. "$HOME/.cargo/env"

# Initialize Starship prompt
/usr/bin/neofetch --color_blocks off
eval "$(starship init bash)"