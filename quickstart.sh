#!/bin/bash

cloneRepo() {
    echo "[+] Checking if shell-setup directory exists..."
    cd ~/
    if [ -d "shell-setup" ]; then
        echo "[+] shell-setup directory already exists. Skipping clone..."
        cd shell-setup/
    else
        echo "[+] Cloning shell-setup..."
        git clone https://github.com/HuskyHacks/shell-setup.git && cd shell-setup/
    fi

    echo "[+] Running setup.sh..."
    ./setup.sh
}

main() {
    echo "[+] One mattlab, coming right up!"
    cloneRepo
}

main