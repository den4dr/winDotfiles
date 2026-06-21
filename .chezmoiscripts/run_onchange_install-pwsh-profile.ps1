$stub = '$p = "$HOME\.config\powershell\profile.ps1"; if (Test-Path $p) { . $p }'
$target = $PROFILE.CurrentUserAllHosts

New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
Set-Content -Path $target -Value $stub -Encoding utf8
