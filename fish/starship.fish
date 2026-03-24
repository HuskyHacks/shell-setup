if type -q starship
    if not starship init fish | source 2>/dev/null
        starship init fish --print-full-init \
            | sed 's/"$(commandline)"/(commandline | string collect)/' \
            | source
    end
end
