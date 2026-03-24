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

```powershell
irm https://raw.githubusercontent.com/HuskyHacks/shell-setup/main/quickstart.ps1 | iex
```

**Clone and install**

```powershell
git clone https://github.com/HuskyHacks/shell-setup.git
Set-Location shell-setup
./setup.ps1
```

Use `./setup.ps1 -Force` to overwrite an existing Starship config. Install [Starship](https://starship.rs/) if the script reports it missing (e.g. `winget install Starship.Starship`). Use a [Nerd Font](https://www.nerdfonts.com/) in your terminal for glyphs.

## PowerShell (`pwsh`)

On Linux/WSL, `./setup.sh` installs PowerShell on Ubuntu (via `packages.microsoft.com`), copies [`powershell/Microsoft.PowerShell_profile.ps1`](powershell/Microsoft.PowerShell_profile.ps1) to `~/.config/powershell/`, and reuses the same [`Starship/starship.toml`](Starship/starship.toml) as Fish/Bash.

On Windows, use the [Windows quickstart](#windows) (`quickstart.ps1` or `./setup.ps1` after cloning).
