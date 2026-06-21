# 0003. statusLine スクリプトの実装方針

Status: Accepted

## Context

Claude Code の statusLine は `settings.json` に `"type": "command"` でコマンドを指定すると、
JSON セッションデータを stdin に流し込んで実行し、stdout を表示する。
Windows では Git Bash がある場合は Git Bash 経由、なければ PowerShell 経由で実行される。

当初は bash スクリプト（`statusline.sh`）で実装したが、JSON 解析に `grep -o ... | cut` を使っており
フィールド名の変更や値のエスケープに脆弱だった。PowerShell への移行を検討する中でいくつかの
落とし穴を踏んだため、ここに記録する。

## Decision

**`pwsh`（PowerShell 7+）で実行し、`ConvertFrom-Json` でネイティブ JSON 解析する。**

```json
"command": "pwsh -NoProfile -File ~/.claude/statusline.ps1"
```

## 非自明な実装上の判断

### 1. `powershell` ではなく `pwsh` を使う

`powershell` は Windows PowerShell 5.1 を指す。
5.1 はバックティック-e（`` `e ``）をエスケープ文字として解釈しない（リテラル `e` として出力する）。
PowerShell 7（`pwsh`）のみが `` `e `` → ESC（0x1B）に展開するため、ANSI カラーコードに必須。

### 2. stdin の読み取りは `$input | Out-String | ConvertFrom-Json`

`[Console]::In.ReadToEnd()` は EOF が来るまでブロックする。
Claude Code が statusLine コマンドを起動する際、stdin の EOF が即座に来るとは限らず、
これを使うとスクリプトが応答なしになって何も表示されなかった。

PowerShell の自動変数 `$input` はパイプライン入力を遅延評価で保持しており、
`Out-String` でまとめて文字列化してから `ConvertFrom-Json` に渡すのが正しいパターン。

### 3. `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` をスクリプト冒頭で設定する

PowerShell のデフォルト出力エンコーディングは OS ロケールに従うため、
Windows 環境では BOM なし UTF-16 LE や Shift_JIS になる場合がある。
Nerd Font グリフ（U+E0B0 等）はこれらのエンコーディングで表現できず `?` になる。
スクリプト冒頭で明示的に UTF-8 を設定することで回避する。

## Alternatives considered

- **bash + jq** — jq が入っていれば JSON 解析が綺麗になる。
  ただし Windows で `bash script.sh` と明示的に呼ぶと Git Bash ウィンドウが別途開く問題があり、
  shebang 経由（`~/.claude/statusline.sh`）でのみ回避可能。将来的な移植性を考え PowerShell を採用。
- **Node.js** — `process.stdin.on('data', ...)` で非同期に stdin を読める。
  `fs.readFileSync(0)` を試みたが Windows では挙動が不安定だった。
  追加ランタイム依存を避けるため不採用。

## Consequences

- `dot_claude/executable_statusline.sh` は chezmoi ソースから削除可能だが、
  ロールバック用に残している（ADR 0002 の Decision 内の記述は ps1 移行後も更新していない）。
- `dot_claude/statusline.ps1`（実行ビット不要、chezmoi は `executable_` 接頭辞なしで管理）が
  `~/.claude/statusline.ps1` に展開される。
- PowerShell 7 が未インストールの環境では動作しない。
  当リポジトリは Windows 11 + pwsh 7 専用のため許容する。
