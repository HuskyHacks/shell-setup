#!/bin/bash

cloneRepo() {
    echo "[+] Cloning..."
    cd ~/
    git clone https://github.com/HuskyHacks/shell-setup.git && cd shell-setup/
    echo "[+] Running setup.sh..."
    ./setup.sh
}

main() {
    echo "[+] One mattlab, coming right up!"
    cloneRepo
}

main