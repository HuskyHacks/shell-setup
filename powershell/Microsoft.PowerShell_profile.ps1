#requires -Version 7

if ([Environment]::GetCommandLineArgs() -contains '-NonInteractive') {
    return
}

function Add-PathPrefix {
    param([string]$Dir)
    if ([string]::IsNullOrWhiteSpace($Dir)) { return }
    if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { return }
    $sep = [IO.Path]::PathSeparator
    $paths = $env:PATH -split [regex]::Escape($sep) | Where-Object { $_ }
    if ($paths -contains $Dir) { return }
    $env:PATH = "$Dir$sep$($paths -join $sep)"
}

$homeLocalBin = Join-Path $HOME '.local/bin'
Add-PathPrefix $homeLocalBin

if (-not $IsWindows) {
    $cargoBin = Join-Path $HOME '.cargo/bin'
    Add-PathPrefix $cargoBin
    if (Test-Path '/usr/local/go/bin') {
        Add-PathPrefix '/usr/local/go/bin'
    }
}

function Invoke-WithSudo {
    param([Parameter(ValueFromRemainingArguments = $true)] [object[]]$Args)
    & sudo @Args
}

function dockershellhere {
    param([Parameter(ValueFromRemainingArguments = $true)] [object[]]$Args)
    $dirname = Split-Path -Leaf (Get-Location).Path
    $pwdPath = (Get-Location).Path
    Invoke-WithSudo docker run --rm -it --entrypoint=/bin/bash -v "${pwdPath}:/${dirname}" -w "/${dirname}" @Args
}

function dockershellshhere {
    param([Parameter(ValueFromRemainingArguments = $true)] [object[]]$Args)
    $dirname = Split-Path -Leaf (Get-Location).Path
    $pwdPath = (Get-Location).Path
    Invoke-WithSudo docker run --rm -it --entrypoint=/bin/sh -v "${pwdPath}:/${dirname}" -w "/${dirname}" @Args
}

function pythonserve {
    param([int]$Port = 8000)
    python3 -m http.server $Port
}

function guidnow {
    param([Parameter(Mandatory = $true)] [int]$N)
    if ($N -lt 1) {
        Write-Error 'N must be a positive integer.'
        return
    }
    for ($i = 0; $i -lt $N; $i++) {
        if ($IsWindows) {
            [guid]::NewGuid().ToString()
        } else {
            & uuidgen
        }
    }
}

function poetry-shell {
    if (-not (Get-Command poetry -ErrorAction SilentlyContinue)) {
        Write-Error 'poetry not found.'
        return
    }
    $activate = poetry env activate 2>&1 | Out-String
    Invoke-Expression $activate.Trim()
}

if (-not $IsWindows) {
    function __gnu_exe {
        param([string]$Name)
        foreach ($d in @('/usr/bin', '/bin')) {
            $p = Join-Path $d $Name
            if (Test-Path -LiteralPath $p) { return $p }
        }
        $cmd = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd) { return $cmd.Source }
        return $null
    }
    $lsExe = __gnu_exe 'ls'
    if ($lsExe) {
        Remove-Alias ls -Force -ErrorAction SilentlyContinue
        function ls { & $lsExe --color=auto @args }
    }
    foreach ($name in @('grep', 'fgrep', 'egrep', 'diff', 'ip')) {
        $exe = __gnu_exe $name
        if (-not $exe) { continue }
        Remove-Alias $name -Force -ErrorAction SilentlyContinue
        $exeEsc = $exe -replace '''', ''''''
        Invoke-Expression @"
function global:$name {
    param([Parameter(ValueFromRemainingArguments = `$true)] [object[]]`$args)
    & '$exeEsc' --color=auto @args
}
"@
    }
    function ll { ls -alFh @args }
    function la { ls -Ah @args }
    function l { ls -CFh @args }
} else {
    Set-Alias ll Get-ChildItem
}

function flag {
    if ($IsWindows) {
        $bytes = New-Object byte[] 16
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $hex = -join ($bytes | ForEach-Object { $_.ToString('x2') })
        "flag{$hex}"
    } else {
        & bash -lc 'head /dev/urandom | md5sum | cut -d " " -f1 | xargs printf "flag{%s}\n"'
    }
}

function dockershell {
    param([Parameter(ValueFromRemainingArguments = $true)] [object[]]$Args)
    Invoke-WithSudo docker run --rm -i -t --entrypoint=/bin/bash @Args
}

function dockershellsh {
    param([Parameter(ValueFromRemainingArguments = $true)] [object[]]$Args)
    Invoke-WithSudo docker run --rm -i -t --entrypoint=/bin/sh @Args
}

function global:__jn_init {
    param(
        [switch]$Open,
        [string]$Python,
        [Parameter(Position = 0)] [string]$Project
    )
    if (-not (Get-Command poetry -ErrorAction SilentlyContinue)) {
        Write-Host 'Poetry not found – install it first.' -ForegroundColor Red
        return
    }
    if ([string]::IsNullOrWhiteSpace($Project)) {
        $Project = Split-Path -Leaf (Get-Location).Path
    }
    $notebook = "$Project.ipynb"
    if (Test-Path -LiteralPath 'pyproject.toml') {
        Write-Host 'pyproject.toml already exists – aborting.' -ForegroundColor Yellow
        return
    }
    poetry init --name $Project --description '' -n
    if (-not [string]::IsNullOrWhiteSpace($Python)) {
        poetry env use $Python 2>&1 | Out-Null
    }
    poetry add --group dev jupyterlab JLDracula 2>&1 | Out-Null
    poetry install --no-root 2>&1 | Out-Null
    @'
{
 "cells": [],
 "metadata": {
   "kernelspec": {
     "display_name": "Python 3",
     "language": "python",
     "name": "python3"
   },
   "language_info": { "name": "python" }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
'@ | Set-Content -LiteralPath $notebook -Encoding utf8
    New-Item -ItemType Directory -Path 'data' -Force | Out-Null
    if (Test-Path -LiteralPath 'README.md') {
        $title = "# $Project`n`n"
        $title + (Get-Content -Raw -LiteralPath 'README.md') | Set-Content -LiteralPath 'README.md.tmp' -Encoding utf8
        Move-Item -Force 'README.md.tmp' 'README.md'
    } else {
        Set-Content -LiteralPath 'README.md' -Value "# $Project" -Encoding utf8
    }
    Write-Host 'Ready!' -ForegroundColor Green
    Write-Host "Run:  poetry run jupyter lab $notebook"
    if ($Open) {
        $poetryExe = (Get-Command poetry -ErrorAction Stop).Source
        Start-Process -FilePath $poetryExe -ArgumentList @('run', 'jupyter', 'lab', $notebook)
    }
}

Set-Alias -Name jupyter-notebook-init -Value __jn_init -Scope Global -Force

$__interactive = $Host.UI -and $Host.Name -ne 'ServerRemoteHost'

if ($__interactive) {
    if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
        Set-PSReadLineOption -Colors @{
            Command            = '#8be9fd'
            Comment            = '#6272a4'
            ContinuationPrompt = '#50fa7b'
            Default            = '#f8f8f2'
            Emphasis           = '#ff79c6'
            Error              = '#ff5555'
            InlinePrediction   = '#6272a4'
            Keyword            = '#ff79c6'
            Member             = '#50fa7b'
            Number             = '#bd93f9'
            Operator           = '#50fa7b'
            Parameter          = '#ffb86c'
            Selection          = '#44475a'
            String             = '#f1fa8c'
            Type               = '#8be9fd'
            Variable           = '#f8f8f2'
        }
    }

    if (Get-Command neofetch -ErrorAction SilentlyContinue) {
        & neofetch --color_blocks off
    }

    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Invoke-Expression (& starship init powershell)
    }

    $compDir = Join-Path (Split-Path $PROFILE -Parent) 'completions'
    foreach ($f in @('uv.ps1', 'uvx.ps1', 'poetry.ps1')) {
        $p = Join-Path $compDir $f
        if (Test-Path -LiteralPath $p) {
            . $p
        }
    }
}
