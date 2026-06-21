# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Windows 環境（PowerShell）向けの個人 dotfiles リポジトリ。**chezmoi** で管理。WSL は管理対象外。

## PowerShell Profile の配線

`$PROFILE`（`OneDrive\...\PowerShell\profile.ps1`）は chezmoi の destDir（`$HOME`）外にあるため直接管理できない。代わりに以下の構成を取る：

- **本体**: `dot_config\powershell\profile.ps1` → `$HOME\.config\powershell\profile.ps1` に展開
- **スタブ**: `chezmoi apply` 時に `.chezmoiscripts` の run-script が `$PROFILE.CurrentUserAllHosts` へ書き込む。ファイル未展開時もエラーにならないよう `Test-Path` で guard している。

## Not Managed by Chezmoi

- `$PROFILE.CurrentUserCurrentHost`（`Microsoft.PowerShell_profile.ps1`）— PowerToys 等が自動生成するため除外
- `~\.config\JetBrains\` — バイナリ/自動生成ファイル、JetBrains IDE が管理
