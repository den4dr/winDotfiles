# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository for a Windows/WSL2 environment, managed with **chezmoi**.

## Chezmoi Setup

```sh
# リポジトリに入ると mise.toml により chezmoi が自動で有効化される
cd /path/to/this/repo
mise install   # chezmoi をインストール

# Initialize chezmoi pointing at this repo
chezmoi init --source $(pwd)

# Preview what would change
chezmoi diff

# Apply dotfiles to $HOME
chezmoi apply
```

## Repository Structure

| Path in repo | Deploys to |
|---|---|
| `dot_zshrc` | `$HOME/.zshrc` |
| `dot_gitconfig` | `$HOME/.gitconfig` |
| `dot_zlogin` / `dot_zprofile` / `dot_zshenv` | `$HOME/.zlogin` etc. |
| `dot_config/mise/config.toml` | `$HOME/.config/mise/config.toml` |
| `dot_config/starship.toml` | `$HOME/.config/starship.toml` |
| `dot_config/git/ignore` | `$HOME/.config/git/ignore` |
| `dot_config/zellij/config.kdl` | `$HOME/.config/zellij/config.kdl` |
| `private_dot_env.secret.tmpl` | `$HOME/.env.secret` (mode 600, rendered from template) |

## Key Tools Configured

- **chezmoi** — Dotfile manager; `mise.toml`（リポジトリローカル）で管理
- **zinit** — Zsh plugin manager (bootstrapped inside `.zshrc`)
- **mise** — Runtime version manager; グローバルで `ghq`, `node@24`, `uv`, `zellij` を管理
- **starship** — Shell prompt using gruvbox dark palette
- **zoxide** — Smart directory jumper (`z` command), initialized in `.zshrc`
- **fzf** — Fuzzy finder; `fbr()` helper in `.zshrc` for interactive git branch switching
- **Bitwarden CLI (`bw`)** — Secrets unlocked via `bw_unlock()` using env vars from `~/.env.secret`

## Secrets

`~/.env.secret` は `private_dot_env.secret.tmpl` から chezmoi が生成（mode 600）。gitignore 済み。
初回 `chezmoi apply` 時に Bitwarden 認証情報を対話プロンプトで入力し、`~/.config/chezmoi/chezmoi.toml` にキャッシュされる。
`.zshrc` がログイン時に source して環境変数にセットする。

```sh
export BW_CLIENTID="..."
export BW_CLIENTSECRET="..."
```

## Not Managed by Chezmoi

- `~/.config/JetBrains/` — binary/auto-generated files, managed by JetBrains IDE directly
