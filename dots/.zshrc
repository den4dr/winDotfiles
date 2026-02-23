### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

### zinit plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zdharma/history-search-multi-word

### environmental value
export PATH=$PATH:/snap/bin
export PATH="$HOME/.local/bin:$PATH"

### service activation
setopt hist_ignore_all_dups             # 重複を記録しない
setopt hist_ignore_space                # スペース始まりのコマンドは記録しない
setopt hist_reduce_blanks               # 余分なスペース排除
setopt hist_verify                      # historyから実行時に確認
setopt share_history                    # 履歴ファイルを共有
setopt extended_history                 # zshの開始終了を記録
eval "$(zoxide init zsh)"

### mise
eval "$(/usr/bin/mise activate zsh)"
eval "$(starship init zsh)"

# zsh hooks
zshaddhistory() {
    [[ "$?" == 0 ]]
}

# Bitwarden認証情報をローカルから読む
[ -f ~/.env.secret ] && source ~/.env.secret

# bwセッションを取得する関数
bw_unlock() {
    export BW_SESSION=$(bw unlock --raw)
}

# fzf methods
# fbr - checkout git branch (including remote branches)
fbr() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git switch $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}


