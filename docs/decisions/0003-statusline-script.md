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

### 2. stdin は UTF-8 の `StreamReader` で生読みする（`$input` は使わない）

```powershell
$reader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.UTF8Encoding]::new($false))
$json = $reader.ReadToEnd() | ConvertFrom-Json
```

当初は `$input | Out-String | ConvertFrom-Json` を使っていた（`[Console]::In.ReadToEnd()` は
EOF を待ってブロックするとされたため）。しかしこれは **文字エンコーディングの罠** を踏む。

Claude Code が `pwsh` を spawn する際、入力コードページは OS 既定になる
（日本語 Windows では CP932/Shift_JIS）。`$input` はこのコードページで **デコード済み** の状態でスクリプトに渡るため、
JSON 内の非 ASCII（例：自動生成される日本語の `session_name`）が UTF-8→CP932 で誤デコードされ、
文字列の終端 `"` が壊れて `ConvertFrom-Json: Unterminated string` で失敗する。
`$json` が null になり、ディレクトリ・モデル・コンテキスト使用量など JSON 由来のセグメントだけが消える
（git と時刻は JSON 非依存なので残る）。**新規セッションは `session_name` が無いため再現せず、
セッションを resume したときだけ発症する** ため原因が分かりにくい。

`$input` はスクリプト本体が走る前にデコードされるので、冒頭で `[Console]::InputEncoding` を
UTF-8 にしても手遅れ（実測で解析失敗のまま）。標準入力ストリームを UTF-8 指定の `StreamReader` で
自前に読むのが正しい。statusLine の stdin は Claude Code がリダイレクトで渡し書き込み後にクローズするため、
`ReadToEnd()` でも EOF が来てブロックしない（当初の懸念は対話コンソールでの話）。

### 3. `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` をスクリプト冒頭で設定する

PowerShell のデフォルト出力エンコーディングは OS ロケールに従うため、
Windows 環境では BOM なし UTF-16 LE や Shift_JIS になる場合がある。
Nerd Font グリフ（U+E0B0 等）はこれらのエンコーディングで表現できず `?` になる。
スクリプト冒頭で明示的に UTF-8 を設定することで回避する。

### 4. git 状態は `session_id` + `cwd` でキャッシュする（5秒 TTL）

statusLine は「アシスタントメッセージ後／compact後／モード変更時」のイベントごと（300ms デバウンス）
および `refreshInterval` のタイマーごとに起動され、その都度 `git rev-parse` + `git status` を実行していた。
デバウンス境界で短時間に連続実行されると git 呼び出しが重複する。

`$env:TEMP` に `cc-statusline-<session_id>-<hash>.txt` を置き、5秒以内なら git を再実行せずキャッシュを読む。
キャッシュキーは公式ドキュメント推奨どおり `session_id`（セッション内で安定・セッション間で一意）に加え、
`cwd` も含める（同一セッションで作業ディレクトリが変わっても他ディレクトリの git 状態を誤表示しない）。
ファイル名衝突を避けるためキー文字列を MD5 でハッシュ化する
（`String.GetHashCode()` は .NET Core ではプロセス起動ごとにランダム化され、毎回別プロセスの statusLine では安定しないため使えない）。

### 5. `$home` は読み取り専用の自動変数なので使わない

ディレクトリ短縮で `$home = $env:USERPROFILE...` と代入していたが、
`$HOME` は PowerShell の自動変数（読み取り専用）で、`Cannot overwrite variable HOME` エラーが毎回 stderr に出ていた
（stdout は正常に描画されるため UI 上は気づきにくい）。`$userHome` にリネームして回避。

### 6. worktree 名は `workspace.git_worktree` を使う（git 呼び出し不要）

linked worktree 内にいるとき、Claude Code が JSON で `workspace.git_worktree` に worktree 名を渡す
（main tree では absent）。自前で `git worktree list` を叩かずに済む。

### 7. `refreshInterval` は使わない（タイマー起動時は stdin が空になる）

時計・rate limit をアイドル時にも更新する目的で `settings.json` の `statusLine.refreshInterval`（60秒）を一度設定したが、
**タイマー起動時はコマンドに JSON が stdin で渡らない**（実測）。その結果 `$json` が null になり、
ディレクトリ名・モデル・コンテキスト使用量など JSON 由来のセグメントだけが消え、
git（直接コマンド）と時刻（`Get-Date`）のみ残る壊れた表示がアイドル中ずっと残った。
イベント起動（メッセージ後・compact後・モード変更時）では JSON が渡るため、`refreshInterval` を外して
イベント駆動のみに戻した。時計はメッセージごとに更新されれば十分と判断。

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
