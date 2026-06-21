---
name: open-worktree-tab
description: >-
  指定ディレクトリ（worktree など）用の zellij タブを新規に開く。worktree を専用タブで開きたいとき、
  または「このディレクトリを新しい zellij タブで開いて」と頼まれたときに使う。
allowed-tools: PowerShell(zellij action *)
---

# open-worktree-tab

zellij セッション内で、対象ディレクトリ用の新規タブを開き、左右分割した右ペインで Claude Code を起動する。

## 前提

- zellij セッション内で実行されていること（環境変数 `ZELLIJ` が存在）。無ければ何もせず、その旨を伝えて終了する。
- `zellij` と `claude` が PATH 上にあること（通常は満たされる）。

## 入力（Claude 側で確定する）

シェルに解決ロジックを持たせない。次を Claude が文脈から確定し、確定値を直接コマンドへ埋め込む。

- **対象ディレクトリ** `<dir>`: 引数があればそれ。無ければ「直前に作成／チェックアウトした worktree のパス」を文脈から決め、それも無ければ現在の作業ディレクトリ（git worktree ルート）を使う。絶対パスにする。
- **タブ名** `<name>`: `<dir>` の basename（issue 番号やブランチ名が含まれていればそれ）。

## 手順

1. zellij セッション内か確認する（環境変数 `ZELLIJ`）。セッション外なら何もせず「zellij セッション外のため実行できない」と報告して終了。判断はセッション文脈で行い、追加のシェル実行はしない。
2. `<dir>` と `<name>` を確定する。
3. 確定値を埋め込み、**zellij コマンドのみ**を1回の PowerShell 呼び出しで実行する（`;` 区切り。各サブコマンドが `zellij action *` にマッチし、`allowed-tools` で無人実行される）。

```powershell
zellij action new-tab --name <name> --cwd <dir>; zellij action new-pane --direction right --cwd <dir> -- claude
```

   - `new-tab --cwd` でタブと左ペインを `<dir>` に置く。
   - `new-pane --direction right --cwd <dir> -- claude` で右ペインを作り、`<dir>` で `claude` を起動する。
4. 開いたタブ名と対象パスを 1 行で報告する。

## 注意

- 無人実行（プロンプト抑止）は frontmatter の `allowed-tools: PowerShell(zellij action *)` に依存する。手順3を `zellij action` 以外のコマンド（`git rev-parse` 等）と混ぜると複合コマンド分解で別サブコマンドが承認対象になり、プロンプトが出るので混ぜない。
- `zellij action` は同期実行。`new-tab` 直後はその新タブにフォーカスがあるため、`new-pane` は同じタブに開く。
- 分割比やボーダーを固定したい場合はレイアウト方式（`new-tab --layout`）に切り替える。現状の最小要件では逐次 action で足りる。
