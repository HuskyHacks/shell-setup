#Requires -Version 7
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Test-WingetExecutable {
    if (-not $IsWindows) { return $false }
    $wa = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
    if ((Test-Path -LiteralPath $wa) -and ($env:Path -notlike "*${wa}*")) {
        $env:Path = "${wa};${env:Path}"
    }
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) { return $false }
    & $winget.Source --version 1>$null 2>$null
    return $LASTEXITCODE -eq 0
}

function Install-WingetFromGitHub {
    $headers = @{ 'User-Agent' = 'shell-setup-setup.ps1' }
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest' -Headers $headers
    $depsAsset = $release.assets | Where-Object { $_.name -ceq 'DesktopAppInstaller_Dependencies.zip' } | Select-Object -First 1
    $bundleAsset = $release.assets | Where-Object { $_.name -ceq 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' } | Select-Object -First 1
    if (-not $depsAsset -or -not $bundleAsset) {
        throw 'Could not find winget release assets on GitHub (DesktopAppInstaller_Dependencies.zip or Microsoft.DesktopAppInstaller msixbundle).'
    }

    $tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $depsZip = Join-Path $tmp 'deps.zip'
        $bundle = Join-Path $tmp 'Microsoft.DesktopAppInstaller.msixbundle'
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $depsAsset.browser_download_url -OutFile $depsZip -Headers $headers
        Invoke-WebRequest -Uri $bundleAsset.browser_download_url -OutFile $bundle -Headers $headers

        $depsDir = Join-Path $tmp 'deps'
        Expand-Archive -LiteralPath $depsZip -DestinationPath $depsDir

        $depsArch = switch ([string][System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
            'Arm64' { 'arm64' }
            'X86' { 'x86' }
            Default { 'x64' }
        }
        $archPath = Join-Path $depsDir $depsArch
        if (-not (Test-Path -LiteralPath $archPath)) {
            throw "winget dependency packages not found for architecture '$depsArch'."
        }

        Get-ChildItem -LiteralPath $archPath -Filter '*.appx' | Sort-Object Name | ForEach-Object {
            Write-Host "[+] Installing winget dependency: $($_.Name)"
            Add-AppxPackage -Path $_.FullName -ErrorAction SilentlyContinue | Out-Null
        }

        Write-Host '[+] Installing App Installer (winget)...'
        Add-AppxPackage -Path $bundle
    }
    finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-NerdFont {
    $version = 'v3.4.0'
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    if (Test-Path -LiteralPath (Join-Path $fontDir 'FiraCodeNerdFontMono-Regular.ttf')) {
        Write-Host '[+] FiraCode Nerd Font already installed - skipping'
        return
    }

    $tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $zip = Join-Path $tmp 'FiraCode.zip'
        $ttfDir = Join-Path $tmp 'ttf'
        $ProgressPreference = 'SilentlyContinue'
        Write-Host "[+] Downloading FiraCode Nerd Font $version..."
        Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/download/$version/FiraCode.zip" -OutFile $zip -Headers @{ 'User-Agent' = 'shell-setup-setup.ps1' }
        Expand-Archive -LiteralPath $zip -DestinationPath $ttfDir

        New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
        $regKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
        New-Item -Path $regKey -Force | Out-Null
        Get-ChildItem -LiteralPath $ttfDir -Filter '*.ttf' -File | ForEach-Object {
            $dest = Join-Path $fontDir $_.Name
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
            Set-ItemProperty -Path $regKey -Name "$($_.BaseName) (TrueType)" -Value $dest
        }
        Write-Host '[+] Installed FiraCode Nerd Font (restart the terminal to pick it up)'
    }
    finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($IsWindows -and -not (Test-WingetExecutable)) {
    Write-Host '[+] winget not found; installing Windows Package Manager from GitHub...'
    try {
        Install-WingetFromGitHub
        $wa = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
        if ((Test-Path -LiteralPath $wa) -and ($env:Path -notlike "*${wa}*")) {
            $env:Path = "${wa};${env:Path}"
        }
        if (-not (Test-WingetExecutable)) {
            Write-Warning 'winget was installed but is not usable in this session. Open a new terminal and run setup.ps1 again, or install Starship manually.'
        }
    }
    catch {
        Write-Warning "Automatic winget install failed: $($_.Exception.Message)"
        Write-Host 'Install App Installer manually: https://github.com/microsoft/winget-cli/releases/latest'
    }
}

if ($IsWindows) {
    try { Install-NerdFont }
    catch { Write-Warning "Nerd Font install failed: $($_.Exception.Message). Install FiraCode manually: https://www.nerdfonts.com/font-downloads" }
}

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

if ($IsWindows) {
    $profileText = Get-Content -LiteralPath $SrcProfile -Raw
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($DestProfile, $profileText, $utf8NoBom)
    Unblock-File -LiteralPath $DestProfile -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $DestProfile -Stream Zone.Identifier -ErrorAction SilentlyContinue

    $compDir = Join-Path $DestDir 'completions'
    if (Test-Path -LiteralPath $compDir) {
        Get-ChildItem -LiteralPath $compDir -Filter '*.ps1' -File -ErrorAction SilentlyContinue | ForEach-Object {
            Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $_.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue
        }
    }
}
else {
    Copy-Item -LiteralPath $SrcProfile -Destination $DestProfile -Force
}

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
    if ($IsWindows -and (Test-WingetExecutable)) {
        Write-Host '[+] Installing Starship via winget...'
        try {
            $winget = Get-Command winget.exe -ErrorAction Stop
            & $winget.Source install --id Starship.Starship -e --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity -h
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "winget install Starship exited with code $LASTEXITCODE. Install manually: winget install --id Starship.Starship -e --source winget"
            }
        }
        catch {
            Write-Warning "winget could not install Starship: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host ''
        Write-Host 'Starship not found on PATH. Install it, then restart the terminal:'
        if ($IsWindows) {
            Write-Host '  winget install --id Starship.Starship -e --source winget'
            Write-Host '  (or see https://starship.rs/guide/#%F0%9F%AA%B6-installation )'
        }
        else {
            Write-Host '  see https://starship.rs/guide/#%F0%9F%AA%B6-installation'
        }
    }
}
