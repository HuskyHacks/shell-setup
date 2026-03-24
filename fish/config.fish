set fish_greeting ""

function dockershellhere
    set dirname (basename (pwd))
    sudo docker run --rm -it --entrypoint=/bin/bash -v (pwd):/{$dirname} -w /{$dirname} $argv
end

function dockershellshhere
    set dirname (basename (pwd))
    sudo docker run --rm -it --entrypoint=/bin/sh -v (pwd):/{$dirname} -w /{$dirname} $argv
end

function pythonserve
    if test (count $argv) -gt 0
        set port $argv[1]
    else
        set port 8000
    end
    python3 -m http.server $port
end

function guidnow
    if test (count $argv) -ne 1
        echo "Usage: guidnow <N>"
        return 1
    end

    set N $argv[1]
    if test $N -lt 1
        echo "N must be a positive integer."
        return 1
    end

    for i in (seq 1 $N)
        printf (uuidgen)'\n'
    end
end

function poetry-shell
    set -l activate_command (poetry env activate)
    eval $activate_command
end

alias ls 'ls --color=auto'
alias grep 'grep --color=auto'
alias fgrep 'fgrep --color=auto'
alias egrep 'egrep --color=auto'
alias diff 'diff --color=auto'
alias ip 'ip --color=auto'

alias ll 'ls -alFh'
alias la 'ls -Ah'
alias l 'ls -CFh'

alias flag 'head /dev/urandom | md5sum | cut -d " " -f1 | xargs printf "flag{%s}\n"'

alias dockershell 'sudo docker run --rm -i -t --entrypoint=/bin/bash'
alias dockershellsh 'sudo docker run --rm -i -t --entrypoint=/bin/sh'


function __jn_init --description "Poetry + JupyterLab bootstrap (data/ dir, Dracula theme)"
    argparse -N 0 'open' 'python=' -- $argv
    or return 1

    type -q poetry; or begin
        echo (set_color red)"Poetry not found – install it first."(set_color normal)
        return 1
    end

    set project (string trim -- $argv[1])
    test -z "$project"; and set project (basename (pwd))
    set notebook "$project.ipynb"

    if test -e pyproject.toml
        echo (set_color yellow)"pyproject.toml already exists – aborting."(set_color normal)
        return 1
    end

    poetry init --name "$project" --description "" -n

    if set -q _flag_python
        poetry env use $_flag_python >/dev/null
    end

    poetry add --group dev jupyterlab JLDracula >/dev/null
    poetry install --no-root >/dev/null

    printf '%s\n' \
    '{' \
    ' "cells": [],' \
    ' "metadata": {' \
    '   "kernelspec": {' \
    '     "display_name": "Python 3",' \
    '     "language": "python",' \
    '     "name": "python3"' \
    '   },' \
    '   "language_info": { "name": "python" }' \
    ' },' \
    ' "nbformat": 4,' \
    ' "nbformat_minor": 5' \
    '}' > "$notebook"
    mkdir -p data

    if test -e README.md
        printf "# %s\n\n" "$project" | cat - README.md > README.tmp; and mv README.tmp README.md
    else
        printf "# %s\n" "$project" > README.md
    end

    set_color green; echo "Ready!"; set_color normal
    echo "Run:  poetry run jupyter lab $notebook"

    if set -q _flag_open
        poetry run jupyter lab $notebook &
    end
end

alias jupyter-notebook-init='__jn_init'

if test -d /usr/local/go/bin
    fish_add_path -g /usr/local/go/bin
end

if test -d "$HOME/.cargo/bin"
    fish_add_path -g "$HOME/.cargo/bin"
end

fish_add_path -g "$HOME/.local/bin"

if status is-interactive
    if type -q neofetch
        neofetch --color_blocks off
    end
end
