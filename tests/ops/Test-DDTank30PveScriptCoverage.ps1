$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$root = Join-Path $repo 'GameServerScript'
$files = @(Get-ChildItem $root -Filter *.cs -File -Recurse | Where-Object { $_.FullName -notmatch '\\(bin|obj)\\' })
if ($files.Count -ne 142) { throw "Expected 142 canonical GameServerScript source files, found $($files.Count)." }
$projectRaw = Get-Content (Join-Path $root 'GameServerScript.csproj') -Raw
$compilePaths = @([regex]::Matches($projectRaw,'<Compile Include="([^"]+\.cs)"') | ForEach-Object { $_.Groups[1].Value })
if ($compilePaths.Count -ne 142) { throw "GameServerScript.csproj compile count mismatch: $($compilePaths.Count)." }
$compileSet = @{}; $compilePaths | ForEach-Object { $compileSet[$_.ToLowerInvariant()] = $true }
$relativeFiles = @($files | ForEach-Object { $_.FullName.Substring($root.Length + 1) })
foreach ($rel in $relativeFiles) { if (-not $compileSet.ContainsKey($rel.ToLowerInvariant())) { throw "Source missing from csproj: $rel" } }
$critical = @(
    'AI\Game\AigaH.cs',
    'AI\Game\AigaN.cs',
    'AI\Game\AigaS.cs',
    'AI\Game\AigaT.cs',
    'AI\Game\BolactathanS.cs',
    'AI\Messions\Aiga4002.cs',
    'AI\Messions\Aiga4003.cs',
    'AI\Messions\BLTC5001.cs',
    'AI\Messions\DCSM4001.cs',
    'AI\NPC\NullAi.cs',
    'AI\NPC\SeventhHardCageNpc.cs',
    'AI\NPC\SeventhHardFirstBoss.cs',
    'AI\NPC\SeventhHardHouseAi.cs',
    'AI\NPC\SeventhHardMaleAi.cs',
    'AI\NPC\SeventhHardNpc.cs',
    'AI\NPC\SeventhHardSecondBoss.cs',
    'AI\NPC\SeventhNormalFirstBoss.cs',
    'AI\NPC\SeventhNormalHouseAi.cs',
    'AI\NPC\SeventhNormalMaleAi.cs',
    'AI\NPC\SeventhNormalNpc.cs',
    'AI\NPC\SeventhSimpleFirstBoss.cs',
    'AI\NPC\SeventhSimpleNpc.cs',
    'AI\NPC\ThirdSimpleKingThird.cs'
)
foreach ($rel in $critical) { if (-not (Test-Path -LiteralPath (Join-Path $root $rel))) { throw "Missing DB-critical PvE script: $rel" } }
$buildRaw = Get-Content (Join-Path $repo 'deploy\Build-DDTank30.ps1') -Raw
if ($buildRaw -notmatch '\$scripts\.Count -ne 142') { throw 'Build script must enforce the 142-script canonical count.' }
$sourceCommit = '16e24b119f96b93b34ddb148f9a035f71a234e67'
$prov = Get-Content (Join-Path $root 'DK-KHOADO-BACKPORT.md') -Raw
if ($prov -notmatch [regex]::Escape($sourceCommit)) { throw 'DK backport provenance commit is missing.' }
Write-Host 'DDTANK30_PVE_SCRIPT_COVERAGE=PASS total=142 critical=23 dk=46'
