$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script = Join-Path $repo 'deploy\Build-DDTank30GameLogicClr2.ps1'
if (-not (Test-Path -LiteralPath $script)) { throw 'Missing CLR2 Game.Logic build script.' }
$text = Get-Content -LiteralPath $script -Raw

foreach ($needle in @(
    'TargetFrameworkVersion=v3.5',
    'BuildProjectReferences=false',
    '/t:Build',
    'Remove-Item -LiteralPath $output',
    'build output is stale',
    'v2.0.50727',
    'mscorlib',
    'System.Drawing',
    'DDTANK30_GAMELOGIC_CLR2_BUILD=PASS'
)) {
    if (-not $text.Contains($needle)) {
        throw "Missing CLR2 Game.Logic build contract: $needle"
    }
}
if ($text -match '/t:Rebuild') {
    throw 'CLR2 Game.Logic build must not use Rebuild because stale FileListAbsolute paths can make Clean unsafe and non-deterministic.'
}
if ($text -match 'TerrainCharacterSettlePatch') {
    throw 'Legacy terrain binary patcher must not be part of the CLR2 Game.Logic build path.'
}

$tracked = @(git -C $repo ls-files -- 'Game.Logic/bin/Release/Game.Logic.dll' 'Game.Logic/bin/Release/Game.Logic.pdb')
if ($tracked.Count -gt 0) {
    throw "Prebuilt Game.Logic artifacts must not be tracked: $($tracked -join ', ')"
}

Write-Host 'DDTANK30_GAMELOGIC_CLR2_BUILD_CONTRACT=PASS'
