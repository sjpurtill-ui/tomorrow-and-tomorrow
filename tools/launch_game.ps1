param(
    [switch]$Fullscreen = $true,
    [switch]$Editor
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$canonicalRoot = 'C:\Users\sjpur\TomorrowandTomorrow'
if ([IO.Path]::GetFullPath($projectRoot).TrimEnd('\') -ine $canonicalRoot) {
    throw "This launcher is outside the current game. Run $canonicalRoot\tools\launch_game.ps1 instead."
}
$godotPackageRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe'
$godotExecutable = Get-ChildItem -LiteralPath $godotPackageRoot -Filter 'Godot_v*-stable_win64.exe' -File |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($null -eq $godotExecutable) {
    throw "Godot executable was not found under $godotPackageRoot"
}

# Codex and terminals opened before the key was configured do not inherit a
# later user-environment change. Explicitly copy the user-scoped credential
# into this launcher's process without storing or printing it.
$openAiKey = [Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'User')
$leviathanKey = [Environment]::GetEnvironmentVariable('LEVIATHAN_AI_API_KEY', 'User')
if (-not [string]::IsNullOrWhiteSpace($leviathanKey)) {
    $env:LEVIATHAN_AI_API_KEY = $leviathanKey
} elseif (-not [string]::IsNullOrWhiteSpace($openAiKey)) {
    $env:OPENAI_API_KEY = $openAiKey
}

$configuredModel = [Environment]::GetEnvironmentVariable('LEVIATHAN_AI_MODEL', 'User')
$env:LEVIATHAN_AI_MODEL = if ([string]::IsNullOrWhiteSpace($configuredModel)) { 'gpt-5.6-terra' } else { $configuredModel }

$arguments = @('--path', ('"' + $projectRoot + '"'))
if ($Editor) {
    $arguments += @('--editor', 'res://main.tscn')
} elseif ($Fullscreen) {
    $arguments += '--fullscreen'
}

$process = Start-Process -FilePath $godotExecutable.FullName -ArgumentList $arguments -WorkingDirectory $projectRoot -PassThru
$buildCommit = & git -C $projectRoot rev-parse --short HEAD
if ($LASTEXITCODE -ne 0) { $buildCommit = 'unknown' }
$launchKind = if ($Editor) { 'canonical editor' } else { 'current game' }
Write-Output "Launched $launchKind from $projectRoot, build $buildCommit (PID $($process.Id)); AI credential present: $([bool](-not [string]::IsNullOrWhiteSpace($env:LEVIATHAN_AI_API_KEY) -or -not [string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)))"
