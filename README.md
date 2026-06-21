# winDotfiles

Windows 環境（PowerShell）向けの個人 dotfiles リポジトリ。[chezmoi](https://www.chezmoi.io/) で管理。

## Setup

```powershell
# リポジトリに入ると mise.toml により chezmoi が自動で有効化される
mise install   # chezmoi をインストール

# Initialize chezmoi pointing at this repo
chezmoi init --source (Get-Location)

# Preview what would change
chezmoi diff

# Apply dotfiles to $HOME
chezmoi apply
```
