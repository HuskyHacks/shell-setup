$ErrorActionPreference = 'Stop'

$QuickstartSourceUrl = 'https://raw.githubusercontent.com/HuskyHacks/shell-setup/main/quickstart.ps1'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwsh) {
        Write-Error @'
PowerShell 7 is required (setup.ps1 uses #Requires -Version 7). Install it, then run again:

  winget install Microsoft.PowerShell

Then open PowerShell 7 (pwsh) and re-run the quickstart one-liner, or run:  pwsh -File .\quickstart.ps1
'@
        exit 1
    }

    $path = $MyInvocation.MyCommand.Path
    if ($path) {
        & $pwsh.Path -NoProfile -ExecutionPolicy Bypass -File $path @args
    }
    else {
        $cmd = "& { irm '$QuickstartSourceUrl' | iex }"
        & $pwsh.Path -NoProfile -ExecutionPolicy Bypass -Command $cmd
    }
    exit $LASTEXITCODE
}

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
