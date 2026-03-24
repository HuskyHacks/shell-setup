#Requires -Version 7
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$RepoRoot = $PSScriptRoot
$DestProfile = [string]$PROFILE
$DestDir = [System.IO.Path]::GetDirectoryName($DestProfile)
if ([string]::IsNullOrEmpty($DestDir)) {
    throw "Could not resolve profile directory from PROFILE path: $DestProfile"
}

$SrcProfile = Join-Path $RepoRoot 'powershell/Microsoft.PowerShell_profile.ps1'
$SrcStarship = Join-Path $RepoRoot 'Starship/starship.toml'

if (-not (Test-Path -LiteralPath $SrcProfile)) {
    throw "Missing repo file: $SrcProfile"
}
if (-not (Test-Path -LiteralPath $SrcStarship)) {
    throw "Missing repo file: $SrcStarship"
}

New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
Copy-Item -LiteralPath $SrcProfile -Destination $DestProfile -Force

$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
$StarshipDestDir = $configHome
$StarshipDest = Join-Path $StarshipDestDir 'starship.toml'

New-Item -ItemType Directory -Path $StarshipDestDir -Force | Out-Null
if ($Force -or -not (Test-Path -LiteralPath $StarshipDest)) {
    Copy-Item -LiteralPath $SrcStarship -Destination $StarshipDest -Force
}
else {
    Write-Host "Keeping existing $StarshipDest (re-run with -Force to overwrite)."
}

Write-Host "Installed profile: $DestProfile"
Write-Host "Installed Starship config: $StarshipDest"

if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "Starship not found on PATH. Install it, then restart the terminal:"
    if ($IsWindows) {
        Write-Host "  winget install Starship.Starship"
        Write-Host "  (or see https://starship.rs/guide/#%F0%9F%AA%B6-installation )"
    }
    else {
        Write-Host "  see https://starship.rs/guide/#%F0%9F%AA%B6-installation"
    }
}
