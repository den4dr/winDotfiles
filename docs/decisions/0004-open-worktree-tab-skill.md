# 0004. worktree を開く zellij 操作のスキル化

Status: Accepted

## Context

Claude Code から zellij を操作して、指定ディレクトリ（多くは issue 用 git worktree）で新規タブを開き、ペインを分割して右ペインで Claude Code を起動する操作を定型化したい。zellij は Windows ネイティブ（mise 経由の `zellij.exe` 0.44.3）でセッション内動作している。

置き場所の候補を検討した。

- **グローバル CLAUDE.md にコマンド直書き** — CLAUDE.md は毎セッション常時コンテキストに載るため、手順・コマンドを書くと肥大化する。
- **PowerShell プロファイル関数** — Claude Code の PowerShell tool は `-NoProfile -NonInteractive` で起動するため、プロファイルの関数は **tool 実行時に読み込まれず呼べない**（[[0002-claude-config-management]] L42 で既知）。対話セッション専用になり、今回の「Claude Code が worktree を開いた流れで呼ぶ」用途に合わない。
- **PATH 上の単体スクリプト** — `-NoProfile` 耐性はあるが、「いつ呼ぶか」のトリガーを別途どこかに書く必要が残る。
- **スキル** — `description` のみ常時ロードされ本体は呼出時に展開される段階的開示。トリガー条件・手順・コマンドを 1 箇所に自己完結でき、モデル自動起動と手動 `/` 起動の両対応。

## Decision

personal skill `~/.claude/skills/open-worktree-tab/SKILL.md` を作成し、起動方式は **自動（description マッチ）＋手動 `/open-worktree-tab` の両方**とする。

- zellij 操作コマンド（`new-tab --cwd` → `new-pane --direction right --cwd <dir> -- claude`）は **SKILL.md に直書き**。2 行程度のため別スクリプトには切り出さない。
- chezmoi は [[0002-claude-config-management]] の **個別ファイル add 方針**に従い、`dot_claude/skills/open-worktree-tab/SKILL.md` 単体を管理する（`~/.claude/skills/` ディレクトリ丸ごとは管理しない）。
- グローバル CLAUDE.md には手順を書かない。発見・起動はスキルの `description` が担う。
- **権限プロンプトの無人化**は frontmatter `allowed-tools: PowerShell(zellij action *)` で行う。スキル有効中のみ列挙ツールを承認なしで実行できる（公式仕様）。PowerShell tool のマッチャは `Bash(...)` ではなく `PowerShell(...)`。permissions は複合コマンドを AST 分解して各サブコマンドにマッチを要求するため、手順3のシェル呼び出しは **`zellij action` のみ**に限定し、dir/name の解決は Claude 側で行ってシェルに混ぜない。

## Alternatives considered

- **CLAUDE.md 直書き** — 常時コンテキスト肥大。却下。
- **プロファイル関数** — `-NoProfile` で tool から呼べない。却下。
- **PATH スクリプト** — トリガー記述が別途必要で自己完結しない。将来コマンドが複雑化したらスキルから外出しする余地として残す。
- **zellij レイアウト（KDL）方式** — 分割比等を宣言的に固定できるが、最小要件では逐次 action で足りる。固定したくなったら `new-tab --layout` に切替。

## Consequences

- zellij セッション内（`ZELLIJ` 環境変数あり）でのみ動作。セッション外では何もせず報告して終了する。
- zellij 0.44.3 の `zellij action new-tab` / `new-pane` の CLI 仕様（`--cwd` / `--direction` / `-- <command>`）に依存する。
- コマンドが増えて複雑化した場合は、SKILL.md から PATH スクリプトへ外出しする（その時点で再判断）。
