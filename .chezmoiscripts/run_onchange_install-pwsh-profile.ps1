$stub = '. "$HOME\.config\powershell\profile.ps1"'
$target = $PROFILE.CurrentUserAllHosts

New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
Set-Content -Path $target -Value $stub -Encoding utf8
