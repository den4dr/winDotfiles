# 0002. ~/.claude 設定の管理方針

Status: Accepted

## Context

zellij / PowerShell 環境を整える流れで、Claude Code の `~/.claude` 配下も chezmoi 管理に取り込みたくなった。ただし `~/.claude` は設定・secret・キャッシュ・セッション状態が同居しており、丸ごとは管理できない。

調査の結果、管理に適すのは手書きの2ファイルのみだった。

- `settings.json` — statusLine 定義・有効プラグイン・マーケットプレース・既定モデル等。
- `statusline.sh` — settings.json が `~/.claude/statusline.sh` として参照する自作 statusLine スクリプト。cwd と model 名を表示するだけの小さな bash ラッパー。

除外すべきものは明確。

- **secret**: `.credentials.json`（OAuth トークン）。コミット厳禁。
- **自動生成・状態・キャッシュ**: `history.jsonl` / `stats-cache.json` / `mcp-needs-auth-cache.json` / `.last-*`、および `backups/` `cache/` `projects/` `sessions/` `shell-snapshots/` `plugins/` 等のディレクトリ。`plugins/` の宣言的設定は `settings.json` 側にあり自動復元されるため不要。

悩ましいのは `settings.json` が **手書き設定とアプリ揮発設定の混在ファイル**である点。`/model` `/config` `/effort` 等でアプリ自身が `model` / `tui` / `effortLevel` / `autoUpdatesChannel` 等を書き換えるため、丸ごと管理するとドリフトが出る。ユーザスコープに `settings.local.json` は無く、揮発フィールドだけ別ファイルへ逃がす分離もできない。

## Decision

`settings.json` と `statusline.sh` を **素の chezmoi ファイルとして管理**する（テンプレート化・マージ処理なし）。

- `dot_claude/settings.json` → `~/.claude/settings.json`
- `dot_claude/executable_statusline.sh` → `~/.claude/statusline.sh`（chezmoi が実行ビットを検知して `executable_` 接頭辞が付く）

揮発フィールドによるドリフトは**許容**し、気づいたら `chezmoi re-add ~/.claude/settings.json` で取り込み直す運用とする。基本設定の書き換え頻度は低く、自動化の複雑さに見合わないため。

## Alternatives considered

- **`modify_` スクリプトでマージ** — 現在のライブファイルを stdin で受け取り、管理キー（statusLine / marketplaces / enabledPlugins）だけ上書きし揮発キーを温存する。ドリフトを原理的に消せて筋は良いが、jq 依存とスクリプト保守が要る。書き換え頻度が低い今は過剰。却下。
- **`ConfigChange` hook で監視** — matcher `user_settings` で `~/.claude/settings.json` 変更を検知し通知/拒否できる。だが (1) ファイルウォッチャ方式ゆえ `/model` 等の揮発書き込みでも発火しノイズになる、(2) 監視 hook 自体が監視対象ファイル内に入る鶏卵問題、(3) セッション中しか動かない。即時アラートが要るときの補助どまりで、主機構には採らない。却下。
- **旧 `statusline-command.{js,ps1,sh}` も管理** — statusLine を `statusline.sh` に切り替えたため、これらは未配線の旧実装。管理対象に含めない。

## Consequences

- 手書きの2ファイル（`settings.json` / `statusline.sh`）が diff / 他マシン再現の対象になる。
- secret・状態・キャッシュは個別 `chezmoi add` のため巻き込まれない（ディレクトリごと add しない）。
- `settings.json` は `/model` 等で差分が出うる。ドリフトは `chezmoi status` で検知し、必要時に `re-add` する前提。
- `.credentials.json` は将来も管理対象外。
- `settings.json` の `env.CLAUDE_CODE_USE_POWERSHELL_TOOL=1` と `defaultShell: powershell` は、PowerShell tool が現状ロールアウトで暗黙有効になっているのを**明示固定**するもの。ロールアウト状態に依存せず全マシンで PowerShell 主シェルを再現するために管理ファイルへ書き込む。なお同 tool は PowerShell プロファイルをロードしないため、profile 側の初期化（[[0001-powershell-profile-wiring]]）は tool 実行コマンドには効かない。
