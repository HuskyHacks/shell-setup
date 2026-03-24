# Shell Setup

Dotfiles and configs for husky@mattlab.

Forked from and inspired by Taggart's [shell setup repo](https://github.com/mttaggart/shell-setup) ♥

## Quickstart

### Linux

> No need to invoke `sudo` when executing the install script. The script will invoke `sudo` and prompt for credentials on its own.

**One-liner**

```bash
curl https://raw.githubusercontent.com/HuskyHacks/shell-setup/main/quickstart.sh | sh
```

**Clone and install**

```bash
git clone https://github.com/HuskyHacks/shell-setup.git
cd shell-setup
./setup.sh
```

This sets up fish as the default prompt, but my bashrc file is in there too if you want to use bash instead.

### Windows

Use [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) (`pwsh`) and [Git for Windows](https://git-scm.com/download/win) (for `git` on `PATH`).

**PowerShell one-liner**

Runs under **PowerShell 7** (`pwsh`). If you paste this into **Windows PowerShell 5.1**, `quickstart.ps1` will restart the same steps in `pwsh` as long as PowerShell 7 is installed (`winget install Microsoft.PowerShell`).

```powershell
irm https://raw.githubusercontent.com/HuskyHacks/shell-setup/main/quickstart.ps1 | iex
```

**Clone and install**

```powershell
git clone https://github.com/HuskyHacks/shell-setup.git
Set-Location shell-setup
./setup.ps1
```

Use `./setup.ps1 -Force` to overwrite an existing Starship config. If winget is missing, `setup.ps1` downloads the latest App Installer bundle and dependencies from the [winget-cli releases](https://github.com/microsoft/winget-cli/releases/latest) and installs them for your user (no Store required). When winget is available, the script also tries to install [Starship](https://starship.rs/) automatically. Use a [Nerd Font](https://www.nerdfonts.com/) in your terminal for glyphs.

## PowerShell (`pwsh`)

On Linux/WSL, `./setup.sh` installs PowerShell on Ubuntu (via `packages.microsoft.com`), copies [`powershell/Microsoft.PowerShell_profile.ps1`](powershell/Microsoft.PowerShell_profile.ps1) to `~/.config/powershell/`, and reuses the same [`Starship/starship.toml`](Starship/starship.toml) as Fish/Bash.

On Windows, use the [Windows quickstart](#windows) (`quickstart.ps1` or `./setup.ps1` after cloning).
