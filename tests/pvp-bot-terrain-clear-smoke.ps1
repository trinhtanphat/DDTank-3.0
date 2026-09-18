$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$helper = Join-Path $root 'Fighting.Server\GameObjects\BotAimTrajectory.cs'
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v3.5\csc.exe'
if (-not (Test-Path $csc)) { throw 'NET35 csc.exe missing' }
$temp = Join-Path $env:TEMP ('ddt30-bot-terrain-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $exe = Join-Path $temp 'probe.exe'
    & $csc /nologo /target:exe /out:$exe /r:System.Drawing.dll $helper (Join-Path $PSScriptRoot 'fixtures\BotAimTrajectoryTerrainHarness.cs')
    if ($LASTEXITCODE -ne 0) { throw "terrain probe compile failed: $LASTEXITCODE" }
    & $exe
    if ($LASTEXITCODE -ne 0) { throw "terrain probe failed: $LASTEXITCODE" }
} finally {
    Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output 'DDT30_PVP_BOT_TERRAIN_CLEAR_SMOKE=PASS'
