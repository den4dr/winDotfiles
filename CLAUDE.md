# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Windows 環境（PowerShell）向けの個人 dotfiles リポジトリ。**chezmoi** で管理。WSL は管理対象外。

## Not Managed by Chezmoi

- `$PROFILE.CurrentUserCurrentHost`（`Microsoft.PowerShell_profile.ps1`）— PowerToys 等が自動生成するため除外
- `~\.config\JetBrains\` — バイナリ/自動生成ファイル、JetBrains IDE が管理

## Design Decisions

設計判断の経緯は ADR として `docs/decisions/` に記録している。仕組みを変更する前に `docs/decisions/README.md`（一覧）を参照すること。
