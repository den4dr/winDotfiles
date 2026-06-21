# Claude Code statusLine — Starship / Tokyo Night style
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$json = $input | Out-String | ConvertFrom-Json

$cwd     = $json.workspace.current_dir
$model   = $json.model.display_name
$remain  = $json.context_window.used_percentage
$effort  = $json.effort.level
$rl5h    = $json.rate_limits.five_hour.used_percentage
$rl7d    = $json.rate_limits.seven_day.used_percentage

# Tokyo Night palette
function Fg([int]$r,[int]$g,[int]$b) { "`e[38;2;${r};${g};${b}m" }
function Bg([int]$r,[int]$g,[int]$b) { "`e[48;2;${r};${g};${b}m" }
$R   = "`e[0m"
$Sep = [char]0xE0B0  # powerline

# Segments: bg / fg
$s0bg = 163,174,210; $s0fg = 9,12,12      # OS
$s1bg = 118,159,240; $s1fg = 227,229,229  # Dir
$s2bg = 57,66,96;    $s2fg = 118,159,240  # Git
$s3bg = 33,39,54;    $s3fg = 118,159,240  # Model
$s4bg = 24,29,44;   $s4fg = 160,169,203  # Rate limits
$s5bg = 29,34,48;    $s5fg = 160,169,203  # Time

# Directory: last 2 non-empty segments, home -> ~
$dir = $cwd -replace '\\','/'
$home = ($env:USERPROFILE -replace '\\','/').TrimEnd('/')
if ($dir.StartsWith($home)) { $dir = '~' + $dir.Substring($home.Length) }
$parts = $dir.Split('/') | Where-Object { $_ -ne '' }
if ($parts.Count -gt 2) { $dir = "$($parts[-2])/$($parts[-1])" }

# Git
$branch = git --no-optional-locks rev-parse --abbrev-ref HEAD 2>$null
$gitSym = ''
if ($branch) {
    $st = git --no-optional-locks status --porcelain 2>$null
    if ($st | Where-Object { $_ -match '^[AM]' })  { $gitSym += '+' }
    if ($st | Where-Object { $_ -match '^ M| M' }) { $gitSym += '!' }
    if ($st | Where-Object { $_ -match '^\?\?' })  { $gitSym += '?' }
}

# Context
$effortLabel = if ($effort) { " ($effort)" } else { '' }
$ctx = if ($null -ne $remain) { " $([Math]::Round([double]$remain))%" } else { '' }

$t = Get-Date -Format "HH:mm"

$out  = "$(Bg @s0bg)$(Fg @s0fg) 󰍲 $R"
$out += "$(Fg @s0bg)$(Bg @s1bg)$Sep$R"
$out += "$(Bg @s1bg)$(Fg @s1fg) $dir $R"
$out += "$(Fg @s1bg)$(Bg @s2bg)$Sep$R"
if ($branch) {
    $out += "$(Bg @s2bg)$(Fg @s2fg)  $branch"
    if ($gitSym) { $out += " $gitSym" }
    $out += " $R"
}
$out += "$(Fg @s2bg)$(Bg @s3bg)$Sep$R"
if ($model) { $out += "$(Bg @s3bg)$(Fg @s3fg)  $model$effortLabel$ctx $R" }
$rlParts = @()
if ($null -ne $rl5h) { $rlParts += "5h:$([Math]::Round([double]$rl5h))%" }
if ($null -ne $rl7d) { $rlParts += "7d:$([Math]::Round([double]$rl7d))%" }
$out += "$(Fg @s3bg)$(Bg @s4bg)$Sep$R"
if ($rlParts.Count -gt 0) {
    $out += "$(Bg @s4bg)$(Fg @s4fg)  $($rlParts -join '  ') $R"
}
$out += "$(Fg @s4bg)$(Bg @s5bg)$Sep$R"
$out += "$(Bg @s5bg)$(Fg @s5fg)   $t $R"
$out += "$(Fg @s5bg)$Sep$R"

[Console]::WriteLine($out)
