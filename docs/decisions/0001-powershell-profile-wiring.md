# 0001. PowerShell プロファイルの配線方式

Status: Accepted

## Context

zellij のデフォルトシェルを PowerShell にしたことで、プロファイル（mise / starship / zoxide / fzf / carapace / ghq の初期化）を chezmoi 管理下に置きたくなった。しかし当環境では以下の制約がある。

- chezmoi の destDir（管理範囲）は `$HOME`（`C:\Users\admin`）。
- PowerShell の `$PROFILE` は OneDrive のドキュメントリダイレクトにより `D:\users\admin\OneDrive\ドキュメント\PowerShell\profile.ps1` に解決される。

つまりプロファイルの実体は **別ドライブ + destDir 外 + OneDrive 同期下** にあり、chezmoi が直接配置できない。

## Decision

「本体は home 配下で管理し、`$PROFILE` にはブートストラップのスタブだけを植える」構成を採用する。

- **本体**: `dot_config\powershell\profile.ps1` → `$HOME\.config\powershell\profile.ps1` に展開（destDir 内なので chezmoi が普通に管理）。
- **スタブ**: `.chezmoiscripts\run_onchange_install-pwsh-profile.ps1` が `chezmoi apply` のたびに `$PROFILE.CurrentUserAllHosts` へ以下を冪等に書き込む。

  ```powershell
  $p = "$HOME\.config\powershell\profile.ps1"; if (Test-Path $p) { . $p }
  ```

  本体が未展開でも PowerShell 起動時にエラーを出さないよう `Test-Path` で guard する。

## Alternatives considered

- **destDir を OneDrive に変更** — 他の dotfiles が全部 `C:\Users\admin` 向けなので破綻。却下。
- **OneDrive 上に symlink を張る** — OneDrive 上の symlink は同期が不安定で、作成に管理者/開発者モードが要る場合がある。却下。
- **Documents を OneDrive から外す** — システム全体の Known Folder に影響し重すぎる。却下。

## Consequences

- 実体が chezmoi 管理になり、diff / 他マシン再現が効く。
- OneDrive 配下に置くのは静的なスタブ1行のみなので、OneDrive 同期と chezmoi の二重管理衝突が起きない。
- `run_onchange_` により新マシンでも `chezmoi apply` 一発でスタブが植わる。
- `$PROFILE.CurrentUserCurrentHost`（`Microsoft.PowerShell_profile.ps1`）は PowerToys 等が自動生成するため管理対象外のまま。
