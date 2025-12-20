#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "[!] Do NOT run this script with sudo."
    echo "    Just execute ./setup.sh as your normal user; it will prompt for your sudo password when needed."
    exit 1
fi

TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

install_apt_packages() {
    echo "[+] Installing apt packages"
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
        ca-certificates curl wget gnupg git \
        cmake gcc pkg-config fish fontconfig libfontconfig1-dev \
        unzip p7zip-full neofetch tmux plocate libnotify4 libsecret-1-0 >/dev/null
}

install_obsidian() {
    echo "[+] Checking for Obsidian…"
    if command -v obsidian >/dev/null 2>&1; then
        echo "[+] Obsidian is already installed – skipping"
        return 0
    fi

    echo "[+] Installing Obsidian…"
    local DEB="$TMPDIR/obsidian_1.4.13_amd64.deb"
    wget -q "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.4.13/obsidian_1.4.13_amd64.deb" -O "$DEB"

    sudo dpkg -i "$DEB" >/dev/null || sudo apt-get -f install -y >/dev/null

    echo "[+] Verifying installation..."
    if ! command -v obsidian >/dev/null 2>&1; then
        echo "[!] Obsidian installation failed."
        return 1
    fi
}

install_docker() {
    echo "[+] Checking for Docker…"
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        echo "[+] Docker & Compose already installed – skipping"
        return 0
    fi

    echo "[+] Installing Docker via get.docker.com"
    local INSTALLER="$TMPDIR/get-docker.sh"
    curl -fsSL https://get.docker.com -o "$INSTALLER" >/dev/null
    sudo sh "$INSTALLER" >/dev/null

    if ! groups "$USER" | grep -q '\bdocker\b'; then
        echo "[+] Adding $USER to docker group"
        sudo usermod -aG docker "$USER"
        ADDED_GROUP=true
    fi

    docker --version >/dev/null 2>&1 || true
    docker compose version >/dev/null 2>&1 || true

    if [[ "${ADDED_GROUP:-}" == true ]]; then
        echo "[i] You’re now in the ‘docker’ group."
        echo "    Log out & back in (or:  newgrp docker ) to activate it."
    fi
}

install_vscode() {
    echo "[+] Checking for VS Code…"
    if command -v code >/dev/null 2>&1; then
        echo "[+] VS Code is already installed – skipping"
        return 0
    fi

    echo "[+] Installing VS Code…"
    local DEB="$TMPDIR/vscode.deb"
    wget -q "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O "$DEB"

    sudo dpkg -i "$DEB" >/dev/null || sudo apt-get -f install -y >/dev/null

    echo "[+] Verifying installation..."
    if ! command -v code >/dev/null 2>&1; then
        echo "[!] VS Code installation failed."
        return 1
    fi

    echo "[+] VS Code installed successfully!"
    code --version || true
}

install_nerdfont() {
    echo "[+] Installing NerdFont"
    if compgen -G "/usr/share/fonts/saucecode-pro/*.ttf" >/dev/null; then
        echo "[+] NerdFont already installed – skipping"
        return 0
    fi

    local ZIP="$TMPDIR/scp.zip"
    local OUT="$TMPDIR/scp"

    wget -qO "$ZIP" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/SourceCodePro.zip"
    mkdir -p "$OUT"
    unzip -qq "$ZIP" -d "$OUT" '*.ttf'
    sudo mkdir -p /usr/share/fonts/saucecode-pro
    sudo mv "$OUT"/*.ttf /usr/share/fonts/saucecode-pro
    sudo fc-cache -s -f >/dev/null
}

install_starship() {
    local VERSION="v1.24.0"
    local ARCH="x86_64-unknown-linux-gnu"
    echo "[+] Checking for Starship (${VERSION})…"

    if command -v starship >/dev/null 2>&1; then
        if starship --version 2>/dev/null | grep -q "starship ${VERSION}"; then
            echo "[+] Starship already at ${VERSION} – skipping"
            return 0
        fi
    fi

    echo "[+] Installing Starship (pinned ${VERSION})"
    local TGZ="$TMPDIR/starship.tar.gz"

    curl -fsSL "https://github.com/starship/starship/releases/download/${VERSION}/starship-${ARCH}.tar.gz" -o "$TGZ"
    tar -xzf "$TGZ" -C "$TMPDIR" starship
    sudo install -m 0755 "$TMPDIR/starship" /usr/local/bin/starship

    starship --version >/dev/null
}

install_poetry() {
    echo "[+] Checking for Poetry…"
    if command -v poetry >/dev/null 2>&1; then
        echo "[+] Poetry already installed – skipping"
        return 0
    fi

    echo "[+] Installing Poetry via install.python-poetry.org"
    curl -sSL https://install.python-poetry.org | python3 - >/dev/null

    local POETRY_BIN="$HOME/.local/bin/poetry"
    if [[ ! -x $POETRY_BIN ]]; then
        echo "[!] Poetry installation failed (binary not found)"; exit 1
    fi
    echo "[+] Poetry installed to $POETRY_BIN"

    if ! grep -qx 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo "[i] Added ~/.local/bin to PATH in ~/.bashrc"
    fi

    if command -v fish >/dev/null 2>&1; then
        mkdir -p ~/.config/fish/conf.d
        local FISH_PATH_SNIPPET=~/.config/fish/conf.d/poetry_path.fish
        if ! grep -q 'fish_user_paths.*\.local/bin' "$FISH_PATH_SNIPPET" 2>/dev/null; then
            echo 'set -Ua fish_user_paths $HOME/.local/bin' > "$FISH_PATH_SNIPPET"
            echo "[i] Added ~/.local/bin to Fish user paths (conf.d/poetry_path.fish)"
        fi

        mkdir -p ~/.config/fish/completions
        poetry completions fish > ~/.config/fish/completions/poetry.fish
        echo "[i] Installed Poetry tab-completion for Fish"
    fi
}

configure_tmux() {
    echo "[+] Configuring tmux"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || true
    cp ./tmux/.tmux.conf ~/.tmux.conf
    echo "[+] Remember: exit all sessions then press Ctrl-B I to install plugins"
}

configure_starship() {
    echo "[+] Configuring Starship prompt"
    mkdir -p ~/.config
    cp ./Starship/starship.toml ~/.config/starship.toml
    grep -qxF 'eval "$(starship init bash)"' ~/.bashrc || \
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
}

configure_fish() {
    echo "[+] Configuring Fish"
    mkdir -p ~/.config/fish/conf.d ~/.config/fish/completions

    cp ./fish/config.fish ~/.config/fish/config.fish
    cp ./fish/dracula.fish ~/.config/fish/conf.d/
    cp ./fish/starship.fish ~/.config/fish/conf.d/starship.fish
    cp ./fish/poetry.fish ~/.config/fish/completions/poetry.fish
}

configure_bashrc() {
    echo "[+] Configuring bashrc"
    cp ./bashrc/.bashrc ~/.bashrc
    echo "[i] bashrc updated. Restart your shell to load changes."
}

configure_neofetch() {
    echo "[+] Configuring neofetch"
    mkdir -p ~/.config/neofetch
    cp ./neofetch/config.conf ~/.config/neofetch/config.conf
    cp ./neofetch/snake.txt   ~/.config/neofetch/snake.txt
}

configure_vscode() {
    echo "[+] Configuring VS Code"

    if ! command -v code >/dev/null 2>&1; then
        echo "[i] VS Code not installed; skipping VS Code config"
        return 0
    fi

    local VSC_USER_DIR="$HOME/.config/Code/User"
    mkdir -p "$VSC_USER_DIR"
    mkdir -p "$VSC_USER_DIR/snippets"

    if [[ -f ./vscode/settings.json ]]; then
        cp ./vscode/settings.json "$VSC_USER_DIR/settings.json"
    fi

    if [[ -f ./vscode/keybindings.json ]]; then
        cp ./vscode/keybindings.json "$VSC_USER_DIR/keybindings.json"
    fi

    if [[ -d ./vscode/snippets ]]; then
        cp -r ./vscode/snippets/. "$VSC_USER_DIR/snippets/"
    fi

    if [[ -f ./vscode/extensions.txt ]]; then
        echo "[+] Installing VS Code extensions (from vscode/extensions.txt)"
        while IFS= read -r ext; do
            [[ -z "$ext" ]] && continue
            code --install-extension "$ext" --force >/dev/null 2>&1 || {
                echo "[i] Failed to install extension: $ext (continuing)"
            }
        done < ./vscode/extensions.txt
    fi
}


ensure_fish_shell() {
    local FISH_BIN
    FISH_BIN="$(command -v fish)"
    if [[ -z "${FISH_BIN:-}" ]]; then
        echo "[!] fish not found"
        return 1
    fi
    if ! grep -qxF "$FISH_BIN" /etc/shells; then
        echo "[+] Adding fish to /etc/shells"
        echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null
    fi
}

welcome() {
    echo "[+] Done! Welcome to mattlab!"

    # For CI/Automation
    if [[ "${CI:-}" == "true" || "${MATT_SKIP_WELCOME:-}" == "1" ]]; then
        echo "[i] CI mode: skipping chsh + exec fish"
        return 0
    fi

    ensure_fish_shell
    sudo chsh -s "$(command -v fish)" "$USER"

    if [[ -t 0 ]]; then
        exec fish
    else
        echo "[i] Shell changed to fish. Start a new session to use it."
    fi
}


main() {
    echo "[+] Bootstrap starting…"
    install_apt_packages
    install_docker
    install_obsidian
    install_vscode
    install_starship
    configure_fish
    install_nerdfont
    install_poetry
    configure_tmux
    configure_vscode
    configure_starship
    configure_neofetch
    configure_bashrc
    welcome
}

main "$@"
