#!/bin/bash

install_apt_packages() {
    echo "[+] Installing apt packages"
    sudo apt update && sudo apt install -y cmake gcc pkg-config fish fontconfig libfontconfig1-dev unzip neofetch
}

install_nerdfont() {
    echo "[+] Installing NerdFont"
    wget -O /tmp/scp.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/SourceCodePro.zip
    unzip /tmp/scp.zip -d /tmp/scp '*.ttf'
    sudo mkdir -p /usr/share/fonts/saucecode-pro
    sudo mv /tmp/scp/*.ttf /usr/share/fonts/saucecode-pro
    rm -rf /tmp/scp
    sudo fc-cache -s -f
}

install_starship() {
    echo "[+] Installing Starship"
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

configure_starship() {
    echo "[+] Configuring Starship"
    mkdir -p ~/.config
    cp ./Starship/starship.toml ~/.config/starship.toml
    grep -qxF 'eval "$(starship init bash)"' ~/.bashrc || echo 'eval "$(starship init bash)"' >> ~/.bashrc
}

configure_fish() {
    echo "[+] Configuring Fish"
    mkdir -p ~/.config/fish
    cp ./fish/* ~/.config/fish
    grep -qxF 'starship init fish | source' ~/.config/fish/config.fish || echo 'starship init fish | source' >> ~/.config/fish/config.fish
}

configure_bashrc() {
    echo "[+] Configuring bashrc"
    cp ./bashrc/.bashrc ~/.bashrc && source ~/.bashrc
}

configure_neofetch() {
    echo "[+] Configuring neofetch"
    mkdir -p ~/.config/neofetch
    cp ./neofetch/config.conf ~/.config/neofetch/config.conf
    cp ./neofetch/snake.txt ~/.config/neofetch/snake.txt
}

welcome() {
    echo "[+] Done! Welcome to mattlab!"
    sudo chsh -s $(which fish) $USER
    exec fish
}

main() {
    echo "[+] Ready!"
    install_apt_packages
    configure_fish
    install_starship
    install_nerdfont
    configure_starship
    configure_neofetch
    configure_bashrc
    welcome
}

main
