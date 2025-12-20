#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "[!] Do NOT run this script with sudo."
    echo "    Just execute ./setup.sh as your normal user; it will prompt for your sudo password when needed."
    exit 1
fi

install_apt_packages() {
    echo "[+] Installing apt packages"
    sudo apt update -y          >/dev/null
    sudo apt install -y \
        cmake  \
        gcc  \
        pkg-config  \
        fish  \
        fontconfig  \
        libfontconfig1-dev \
        unzip  \
        p7zip-full \
        neofetch \
        tmux \
        plocate                  >/dev/null
}

install_docker() {
    echo "[+] Checking for Docker…"
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        echo "[+] Docker & Compose already installed – skipping"
        return 0
    fi

    echo "[+] Installing Docker via get.docker.com"
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh              >/dev/null
    sudo sh /tmp/get-docker.sh                                           >/dev/null

    if ! groups "$USER" | grep -q '\bdocker\b'; then
        echo "[+] Adding $USER to docker group"
        sudo usermod -aG docker "$USER"
        ADDED_GROUP=true
    fi

    docker --version           >/dev/null
    docker compose version     >/dev/null

    if [[ "${ADDED_GROUP:-}" == true ]]; then
        echo "[i] You’re now in the ‘docker’ group."
        echo "    Log out & back in (or:  newgrp docker ) to activate it."
    fi
}

install_nerdfont() {
    echo "[+] Installing NerdFont"
    wget -qO /tmp/scp.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/SourceCodePro.zip
    unzip -qq /tmp/scp.zip -d /tmp/scp '*.ttf'
    sudo mkdir -p /usr/share/fonts/saucecode-pro
    sudo mv /tmp/scp/*.ttf /usr/share/fonts/saucecode-pro
    rm -rf /tmp/scp
    sudo fc-cache -s -f >/dev/null
}

install_starship() {
    echo "[+] Installing Starship"
    curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null
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
        echo "[i] Installed Poetry tab‑completion for Fish"
    fi
}


configure_tmux() {
    echo "[+] Configuring tmux"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || true
    cp ./tmux/.tmux.conf ~/.tmux.conf
    echo "[+] Remember: exit all sessions then press Ctrl‑B I to install plugins"
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
    mkdir -p ~/.config/fish/conf.d
    mkdir -p ~/.config/fish/completions
    cp ./fish/* ~/.config/fish
    cp ./fish/dracula.fish ~/.config/fish/conf.d/
    cp ./fish/poetry.fish ~/.config/fish/completions/poetry.fish
}

configure_bashrc() {
    echo "[+] Configuring bashrc"
    cp ./bashrc/.bashrc ~/.bashrc
    # shellcheck source=/dev/null
    source ~/.bashrc
}

configure_neofetch() {
    echo "[+] Configuring neofetch"
    mkdir -p ~/.config/neofetch
    cp ./neofetch/config.conf ~/.config/neofetch/config.conf
    cp ./neofetch/snake.txt   ~/.config/neofetch/snake.txt
}

welcome() {
    echo "[+] Done! Welcome to mattlab!"
    sudo chsh -s "$(which fish)" "$USER"
    exec fish
}

main() {
    echo "[+] Bootstrap starting…"
    install_apt_packages
    install_docker
    configure_fish
    install_starship
    install_nerdfont
    install_poetry
    configure_tmux
    configure_starship
    configure_neofetch
    configure_bashrc
    welcome
}

main "$@"
