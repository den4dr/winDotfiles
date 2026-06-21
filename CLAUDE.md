# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Windows 環境（PowerShell）向けの個人 dotfiles リポジトリ。**chezmoi** で管理。WSL は管理対象外。

## Chezmoi Setup

```powershell
# リポジトリに入ると mise.toml により chezmoi が自動で有効化される
cd C:\path\to\this\repo
mise install   # chezmoi をインストール

# Initialize chezmoi pointing at this repo
chezmoi init --source (Get-Location)

# Preview what would change
chezmoi diff

# Apply dotfiles to $HOME
chezmoi apply
```

## Repository Structure

| Path in repo | Deploys to |
|---|---|
| `dot_gitconfig` | `$HOME\.gitconfig` |
| `dot_nyagos` | `$HOME\.nyagos` |
| `dot_config\git\ignore` | `$HOME\.config\git\ignore` |
| `dot_config\mise\config.toml` | `$HOME\.config\mise\config.toml` |
| `dot_config\starship.toml` | `$HOME\.config\starship.toml` |
| `dot_config\powershell\profile.ps1` | `$HOME\.config\powershell\profile.ps1` |
| `AppData\Roaming\Zellij\config\config.kdl` | `%APPDATA%\Zellij\config\config.kdl` |
| `.chezmoiscripts\run_onchange_install-pwsh-profile.ps1` | 実行スクリプト（`$PROFILE.CurrentUserAllHosts` にスタブを配置） |

## PowerShell Profile の配線

PowerShell の `$PROFILE`（`OneDrive\...\PowerShell\profile.ps1`）は chezmoi の destDir 外にあるため直接管理できない。
代わりに以下の構成を取る：

- **本体**: `dot_config\powershell\profile.ps1` → `$HOME\.config\powershell\profile.ps1` に展開
- **スタブ**: `chezmoi apply` 時に run-script が `$PROFILE.CurrentUserAllHosts` へ以下を書き込む
  ```powershell
  $p = "$HOME\.config\powershell\profile.ps1"; if (Test-Path $p) { . $p }
  ```

## Key Tools Configured

- **chezmoi** — Dotfile manager; `mise.toml`（リポジトリローカル）で管理
- **mise** — Runtime version manager; `ghq`, `node@24`, `uv`, `zellij` をグローバル管理
- **starship** — Shell prompt (tokyo night パレット); PowerShell プロファイルで初期化
- **zoxide** — Smart directory jumper (`z` コマンド); PowerShell プロファイルで初期化
- **fzf / PSFzf** — Fuzzy finder; `Ctrl+t`（ファイル）・`Ctrl+r`（履歴）にバインド
- **carapace** — 補完ブリッジ; PowerShell プロファイルで初期化
- **nyagos** — Windows 向け Go 製シェル; `dot_nyagos` で starship・zoxide を設定
- **zellij** — Terminal multiplexer; `%APPDATA%\Zellij\config\config.kdl` で PowerShell をデフォルトシェルに設定

## Not Managed by Chezmoi

- `$PROFILE`（`OneDrive\...\PowerShell\profile.ps1`）の実体 — スタブ経由で本体を読み込む
- `$PROFILE.CurrentUserCurrentHost`（`Microsoft.PowerShell_profile.ps1`）— PowerToys 等が自動生成
- `~\.config\JetBrains\` — バイナリ/自動生成ファイル、JetBrains IDE が管理
