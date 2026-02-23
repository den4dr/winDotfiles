# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository for a Windows/WSL2 environment. There is no build system or install script — files are deployed manually (symlink or copy) to their target locations.

## Repository Structure

| Path in repo | Deploys to |
|---|---|
| `dots/.*` | `$HOME/.*` |
| `.config/mise/config.toml` | `$HOME/.config/mise/config.toml` |
| `.config/starship.toml` | `$HOME/.config/starship.toml` |
| `samples/.env.secret` | `$HOME/.env.secret` (template only, not deployed) |

## Key Tools Configured

- **zinit** — Zsh plugin manager (bootstrapped inside `.zshrc`)
- **mise** — Runtime version manager; manages `ghq`, `node@24`, `uv`
- **starship** — Shell prompt using gruvbox dark palette
- **zoxide** — Smart directory jumper (`z` command), initialized in `.zshrc`
- **fzf** — Fuzzy finder; `fbr()` helper in `.zshrc` for interactive git branch switching
- **Bitwarden CLI (`bw`)** — Secrets unlocked via `bw_unlock()` using env vars from `~/.env.secret`

## Secrets

`~/.env.secret` is sourced by `.zshrc` at login and is gitignored. It holds Bitwarden API credentials:

```sh
export BW_CLIENTID="..."
export BW_CLIENTSECRET="..."
```

`samples/.env.secret` is the template committed to the repo.
