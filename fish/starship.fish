# Starship prompt init (with fallback workaround)
# The fish prompt and starship can't seem to stay stable between updates
# Workaround kept for historical Starship/Fish breakages (e.g., commandline quoting).
# If normal init works, we use it. If it fails, fall back to patched full init.

if type -q starship
    if not starship init fish | source 2>/dev/null
        starship init fish --print-full-init \
            | sed 's/"$(commandline)"/(commandline | string collect)/' \
            | source
    end
end
