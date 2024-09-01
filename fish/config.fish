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

# Define color aliases for ls, grep, and related commands
alias ls 'ls --color=auto'
alias grep 'grep --color=auto'
alias fgrep 'fgrep --color=auto'
alias egrep 'egrep --color=auto'
alias diff 'diff --color=auto'
alias ip 'ip --color=auto'

# Additional aliases
alias ll 'ls -alF'
alias la 'ls -A'
alias l 'ls -CF'

# Flag alias to generate random flag strings
alias flag 'head /dev/urandom | md5sum | cut -d " " -f1 | xargs printf "flag{%s}\n"'

# Docker shell aliases
alias dockershell 'sudo docker run --rm -i -t --entrypoint=/bin/bash'
alias dockershellsh 'sudo docker run --rm -i -t --entrypoint=/bin/sh'

# Export PATH and other environment variables
set -gx PATH $PATH /usr/local/go/bin
set -gx PATH $PATH $HOME/.cargo/env

# Initialize Starship prompt
/usr/bin/neofetch --color_blocks off
starship init fish | source
