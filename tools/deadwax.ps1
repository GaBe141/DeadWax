[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('doctor', 'editor', 'play', 'check', 'test', 'vibe', 'help')]
    [string] $Action = 'doctor'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$RequiredGodotSeries = '4.7'

function Get-GodotExecutable {
    param([switch] $Console)

    if ($env:DEADWAX_GODOT -and (Test-Path -LiteralPath $env:DEADWAX_GODOT -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $env:DEADWAX_GODOT).Path
    }

    $packageRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path -LiteralPath $packageRoot -PathType Container) {
        $packageDirectories = Get-ChildItem -LiteralPath $packageRoot -Directory |
            Where-Object { $_.Name -like 'GodotEngine.GodotEngine_*' }
        $exactPattern = if ($Console) {
            'Godot_v4.7.1-stable_win64_console.exe'
        } else {
            'Godot_v4.7.1-stable_win64.exe'
        }
        $fallbackPattern = if ($Console) {
            'Godot_v*-stable_win64_console.exe'
        } else {
            'Godot_v*-stable_win64.exe'
        }

        foreach ($pattern in @($exactPattern, $fallbackPattern)) {
            $candidate = $packageDirectories |
                ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -File -Filter $pattern } |
                Where-Object { $Console -or $_.Name -notlike '*_console.exe' } |
                Sort-Object Name -Descending |
                Select-Object -First 1
            if ($candidate) {
                return $candidate.FullName
            }
        }
    }

    foreach ($commandName in @('godot4', 'godot')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    throw 'Godot was not found. Install Godot 4.7.1 or set DEADWAX_GODOT to its executable.'
}

function Get-VibeExecutable {
    $command = Get-Command vibe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $scriptsRoot = Join-Path $env:APPDATA 'Python'
    if (Test-Path -LiteralPath $scriptsRoot -PathType Container) {
        $candidate = Get-ChildItem -LiteralPath $scriptsRoot -Directory -Filter 'Python*' |
            ForEach-Object { Join-Path $_.FullName 'Scripts\vibe.exe' } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            Sort-Object -Descending |
            Select-Object -First 1
        if ($candidate) {
            return $candidate
        }
    }

    throw 'Mistral Vibe was not found. Run vibe --setup after installing mistral-vibe.'
}

function Get-GodotVersion {
    param([string] $Executable)

    $versionOutput = @(& $Executable --version)
    $versionExitCode = $LASTEXITCODE
    $version = if ($versionOutput.Count -gt 0) { ([string] $versionOutput[0]).Trim() } else { '' }
    if ($versionExitCode -ne 0 -or -not $version) {
        throw "Could not read the Godot version from $Executable"
    }
    if ($version -notmatch ('^' + [regex]::Escape($RequiredGodotSeries) + '(\.|$)')) {
        throw "Dead Wax requires Godot $RequiredGodotSeries.x; found $version"
    }
    return $version
}

function Invoke-Godot {
    param(
        [string] $Executable,
        [string[]] $GodotArguments
    )

    & $Executable @GodotArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Godot exited with code $LASTEXITCODE."
    }
}

function Show-Help {
    @'
Dead Wax developer commands

  deadwax.cmd doctor  Check Godot, Git, Vibe, storage, and repository state.
  deadwax.cmd editor  Open the project in the Godot editor.
  deadwax.cmd play    Run the game directly with a local runtime log.
  deadwax.cmd check   Import resources, then run the native smoke suite.
  deadwax.cmd test    Run only the native smoke suite.
  deadwax.cmd vibe    Start Mistral Vibe in this repository.

The DEADWAX_GODOT environment variable can override Godot discovery.
'@ | Write-Host
}

switch ($Action) {
    'help' {
        Show-Help
    }
    'doctor' {
        $godot = Get-GodotExecutable -Console
        $godotVersion = Get-GodotVersion -Executable $godot
        $gitVersion = (& git --version).Trim()
        if ($LASTEXITCODE -ne 0) {
            throw 'Git is not available.'
        }

        $vibeVersion = 'not found'
        try {
            $vibe = Get-VibeExecutable
            $vibeOutput = @(& $vibe --version)
            $vibeVersion = if ($vibeOutput.Count -gt 0) { ([string] $vibeOutput[0]).Trim() } else { 'unknown' }
        } catch {
            $vibeVersion = $_.Exception.Message
        }

        $drive = Get-PSDrive -Name ([IO.Path]::GetPathRoot($ProjectRoot).Substring(0, 1))
        Write-Host "Project : $ProjectRoot"
        Write-Host "Godot  : $godotVersion"
        Write-Host "Git    : $gitVersion"
        Write-Host "Vibe   : $vibeVersion"
        Write-Host ('Free {0}: {1:N1} GB' -f $drive.Name, ($drive.Free / 1GB))
        Write-Host 'Status :'
        & git -C $ProjectRoot status --short --branch
        if ($LASTEXITCODE -ne 0) {
            throw 'Git status failed.'
        }
    }
    'editor' {
        $godot = Get-GodotExecutable
        $version = Get-GodotVersion -Executable (Get-GodotExecutable -Console)
        Write-Host "Opening Dead Wax in Godot $version"
        Start-Process -FilePath $godot -WorkingDirectory $ProjectRoot -ArgumentList @(
            '--editor', '--path', ('"' + $ProjectRoot + '"')
        ) | Out-Null
    }
    'play' {
        $godot = Get-GodotExecutable
        $version = Get-GodotVersion -Executable (Get-GodotExecutable -Console)
        $cacheDirectory = Join-Path $ProjectRoot '.godot'
        New-Item -ItemType Directory -Path $cacheDirectory -Force | Out-Null
        $logPath = Join-Path $cacheDirectory 'deadwax-play.log'
        Write-Host "Starting Dead Wax with Godot $version"
        Write-Host "Runtime log: $logPath"
        Start-Process -FilePath $godot -WorkingDirectory $ProjectRoot -ArgumentList @(
            '--path', ('"' + $ProjectRoot + '"'), '--log-file', ('"' + $logPath + '"')
        ) | Out-Null
    }
    'test' {
        $godot = Get-GodotExecutable -Console
        $version = Get-GodotVersion -Executable $godot
        Write-Host "Running Dead Wax smoke tests with Godot $version"
        Invoke-Godot -Executable $godot -GodotArguments @(
            '--headless', '--path', $ProjectRoot, '--script', 'res://tests/smoke_test.gd'
        )
    }
    'check' {
        $godot = Get-GodotExecutable -Console
        $version = Get-GodotVersion -Executable $godot
        Write-Host "Importing Dead Wax resources with Godot $version"
        Invoke-Godot -Executable $godot -GodotArguments @(
            '--headless', '--path', $ProjectRoot, '--import'
        )
        Write-Host 'Running native smoke tests'
        Invoke-Godot -Executable $godot -GodotArguments @(
            '--headless', '--path', $ProjectRoot, '--script', 'res://tests/smoke_test.gd'
        )
    }
    'vibe' {
        $vibe = Get-VibeExecutable
        Write-Host 'Starting Mistral Vibe with Dead Wax project instructions...'
        & $vibe --workdir $ProjectRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Vibe exited with code $LASTEXITCODE."
        }
    }
}
