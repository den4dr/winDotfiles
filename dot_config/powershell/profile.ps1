Import-Module PSFzf
Enable-PsFzfAliases

# ~/.config/powershell/Microsoft.PowerShell_profile.ps1
$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression

# 関数定義
function Invoke-PecoGhqCd {
  # ghq list の出力を peco に渡す
  # Zsh の $LBUFFER を peco の初期クエリに渡す機能は、
  # PowerShell + 外部コマンドでは実現が複雑なため省略しています。
  $selectedRepoRelative = ghq list | fzf

  # peco で何か選択されたかチェック
  if (-not [string]::IsNullOrEmpty($selectedRepoRelative)) {
    # 選択されたリポジトリの絶対パスを取得
    # --exact を使うことで、peco が出力した正確な相対パスに一致させます
    $selectedRepoFullPath = ghq list --full-path --exact $selectedRepoRelative

    # 絶対パスが取得できたかチェック
    if (-not [string]::IsNullOrEmpty($selectedRepoFullPath)) {
      # 取得した絶対パスに移動 (cd は Set-Location のエイリアスです)
      z $selectedRepoFullPath
    }
    else {
      # フルパスが見つからなかった場合 (通常は発生しないはずですが念のため)
      Write-Error "Could not find full path for repository: $selectedRepoRelative"
    }
  }
}

# PSReadLine を使って関数をキーバインドに割り当てる
# Ctrl+] に Invoke-PecoGhqCd 関数を割り当てます
Set-PSReadLineKeyHandler -Key 'Ctrl+]' -ScriptBlock {
  Invoke-PecoGhqCd
}
# replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

function gwt {
  param(
    [Parameter(Mandatory=$true)]
    [string]$branch,
    
    [string]$workDir = "$HOME/work"
  )
  
  # プロジェクト名を自動取得
  $remoteUrl = git config --get remote.origin.url
  $project = [System.IO.Path]::GetFileNameWithoutExtension($remoteUrl)
  
  if ([string]::IsNullOrEmpty($branch)) {
    Write-Host "Usage: gwt <branch> [work_dir]"
    return
  }
  
  # prefixを削除（/ の前までを削除）
  $dirname = if ($branch -match '/') {
    $branch -replace '^[^/]+/', ''
  } else {
    $branch
  }
  
  $worktreePath = Join-Path $workDir "$project-$dirname"
  Write-Host "Creating worktree: $worktreePath"
  git worktree add $worktreePath $branch
}

mise activate pwsh | Out-String | Invoke-Expression
Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
