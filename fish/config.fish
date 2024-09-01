function dockershellhere
    set dirname (basename (pwd))
    sudo docker run --rm -it --entrypoint=/bin/bash -v (pwd):/{$dirname} -w /{$dirname} $argv
end

function dockershellshhere
    set dirname (basename (pwd))
    sudo docker run --rm -it --entrypoint=/bin/sh -v (pwd):/{$dirname} -w /{$dirname} $argv
end

# Export PATH and other environment variables
set -gx PATH $PATH /usr/local/go/bin
set -gx PATH $PATH $HOME/.cargo/env

# Initialize Starship prompt
/usr/bin/neofetch --color_blocks off
starship init fish | source
