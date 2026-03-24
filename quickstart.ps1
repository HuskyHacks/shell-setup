#Requires -Version 7
$ErrorActionPreference = 'Stop'

function Main {
    Write-Host '[+] One mattlab, coming right up!'
    $repo = Join-Path $HOME 'shell-setup'
    if (Test-Path -LiteralPath $repo) {
        Write-Host '[+] shell-setup directory already exists. Skipping clone...'
        Push-Location -LiteralPath $repo
    }
    else {
        Write-Host '[+] Cloning shell-setup...'
        git clone https://github.com/HuskyHacks/shell-setup.git $repo
        Push-Location -LiteralPath $repo
    }
    try {
        Write-Host '[+] Running setup.ps1...'
        & (Join-Path $repo 'setup.ps1')
    }
    finally {
        Pop-Location
    }
}

Main
