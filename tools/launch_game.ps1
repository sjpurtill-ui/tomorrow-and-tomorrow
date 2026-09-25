param(
    [switch]$Fullscreen = $true,
    [switch]$Editor,
    [switch]$ResumeSaved = $true,
    [switch]$CaptureOpening
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$canonicalRoot = 'C:\Users\sjpur\TomorrowandTomorrow'
if ([IO.Path]::GetFullPath($projectRoot).TrimEnd('\') -ine $canonicalRoot) {
    throw "This launcher is outside the current game. Run $canonicalRoot\tools\launch_game.ps1 instead."
}
$branch = & git -C $projectRoot branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') {
    throw 'The player launcher requires the integrated main branch. Ask the integrator to finish the release.'
}
$projectConfig = Get-Content -LiteralPath (Join-Path $projectRoot 'project.godot') -Raw
if ($projectConfig -notmatch 'run/main_scene="res://local_terrain.tscn"' -or $projectConfig -match 'config/use_custom_user_dir=true' -or (Test-Path -LiteralPath (Join-Path $projectRoot 'override.cfg'))) {
    throw 'The canonical project contains a test entry point or settings override. Ask the integrator to review it before launching.'
}
if (-not $Editor) {
    $existing = Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^Godot_v.*\.exe$' -and $_.CommandLine -and
        $_.CommandLine.Replace('/', '\').Contains($canonicalRoot) -and
        $_.CommandLine -notmatch '--editor|--headless'
    }
    if ($existing) {
        throw "A canonical game is already running (PID $($existing.ProcessId -join ', ')). Save and exit it normally, then launch again to load the newest release."
    }
}
$godotPackageRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe'
$godotExecutable = Get-ChildItem -LiteralPath $godotPackageRoot -Filter 'Godot_v*-stable_win64.exe' -File |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($null -eq $godotExecutable) {
    throw "Godot executable was not found under $godotPackageRoot"
}

# A Git update can add global script classes and textures that the local
# editor cache has never seen. Import each new commit before player startup.
$importCommit = & git -C $projectRoot rev-parse HEAD
$importMarker = Join-Path $projectRoot '.godot/launcher-import-commit.txt'
$previousImport = if (Test-Path -LiteralPath $importMarker) { (Get-Content -LiteralPath $importMarker -Raw).Trim() } else { '' }
if ($previousImport -ne $importCommit) {
    $importDirectory = Join-Path $projectRoot 'artifacts'
    [IO.Directory]::CreateDirectory($importDirectory) | Out-Null
    $importLog = Join-Path $importDirectory 'launcher-import.log'
    $importArguments = @('--headless', '--editor', '--import', '--path', ('"' + $projectRoot + '"'), '--log-file', ('"' + $importLog + '"'))
    Write-Output 'Importing updated game scripts and artwork before launch...'
    $importProcess = Start-Process -FilePath $godotExecutable.FullName -ArgumentList $importArguments -WorkingDirectory $projectRoot -WindowStyle Hidden -Wait -PassThru
    if ($importProcess.ExitCode -ne 0 -or (Select-String -LiteralPath $importLog -Pattern '^SCRIPT ERROR:|^ERROR:' -Quiet)) {
        throw "Game import failed; player launch stopped. Inspect $importLog"
    }
    [IO.File]::WriteAllText($importMarker, $importCommit)
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
$env:LEVIATHAN_AI_MODEL = if ([string]::IsNullOrWhiteSpace($configuredModel)) { 'gpt-6-luna' } else { $configuredModel }

$launchLogDirectory = Join-Path $projectRoot 'artifacts'
[IO.Directory]::CreateDirectory($launchLogDirectory) | Out-Null
$launchLog = Join-Path $launchLogDirectory ('player-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
$arguments = @('--path', ('"' + $projectRoot + '"'), '--log-file', ('"' + $launchLog + '"'))
if ($Editor) {
    $arguments += @('--editor', 'res://main.tscn')
} elseif ($Fullscreen) {
    $arguments += '--fullscreen'
}

$savedCampaignPath = Join-Path $env:APPDATA 'Godot\app_userdata\Tomorrow and Tomorrow\saves\quicksave.save'
$gameArguments = @()
if ($ResumeSaved -and -not $Editor -and (Test-Path -LiteralPath $savedCampaignPath)) {
    $gameArguments += '--resume-saved'
}
if ($CaptureOpening -and -not $Editor) { $gameArguments += '--capture-opening' }
if ($gameArguments.Count -gt 0) { $arguments += @('--') + $gameArguments }

$process = Start-Process -FilePath $godotExecutable.FullName -ArgumentList $arguments -WorkingDirectory $projectRoot -PassThru
$buildCommit = & git -C $projectRoot rev-parse --short HEAD
if ($LASTEXITCODE -ne 0) { $buildCommit = 'unknown' }
$launchKind = if ($Editor) { 'canonical editor' } else { 'current game' }
Write-Output "Launched $launchKind from $projectRoot, build $buildCommit (PID $($process.Id)); AI credential present: $([bool](-not [string]::IsNullOrWhiteSpace($env:LEVIATHAN_AI_API_KEY) -or -not [string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)))"

Write-Output "Player log: $launchLog"
