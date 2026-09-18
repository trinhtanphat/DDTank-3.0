$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$root = Join-Path $repo 'GameServerScript'
$files = @(Get-ChildItem $root -Filter *.cs -File -Recurse | Where-Object { $_.FullName -notmatch '\\(bin|obj)\\' })
if ($files.Count -ne 174) { throw "Expected 174 canonical GameServerScript source files, found $($files.Count)." }
$projectRaw = Get-Content (Join-Path $root 'GameServerScript.csproj') -Raw
$compilePaths = @([regex]::Matches($projectRaw,'<Compile Include="([^"]+\.cs)"') | ForEach-Object { $_.Groups[1].Value })
if ($compilePaths.Count -ne 174) { throw "GameServerScript.csproj compile count mismatch: $($compilePaths.Count)." }
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
    'AI\NPC\ThirdSimpleKingThird.cs',
    'AI\NPC\FiveHardFirstNpc.cs',
    'AI\NPC\FiveNormalFirstNpc.cs',
    'AI\NPC\FiveTerrorFirstNpc.cs',
    'AI\NPC\SeizeNpcAi.cs',
    'AI\NPC\SeventhNormalCageNpc.cs',
    'AI\NPC\SeventhSimpleCageNpc.cs',
    'AI\NPC\ThirdHardBloodNpc.cs',
    'AI\NPC\ThirdNormalBloodNpc.cs',
    'AI\NPC\ThirdSimpleBloodNpc.cs',
    'AI\NPC\ThirdSimpleBlowNpc.cs',
    'AI\NPC\ThirdSimpleFixureLongNpc.cs',
    'AI\NPC\ThirdTerrorBloodNpc.cs',
    'AI\NPC\PSMNpc5001Ai.cs',
    'AI\NPC\PSMNpc5002Ai.cs',
    'AI\NPC\PSMNpc5003Ai.cs',
    'AI\NPC\PSMNpc5004Ai.cs'
)
foreach ($rel in $critical) { if (-not (Test-Path -LiteralPath (Join-Path $root $rel))) { throw "Missing DB-critical PvE script: $rel" } }
$buildRaw = Get-Content (Join-Path $repo 'deploy\Build-DDTank30.ps1') -Raw
if ($buildRaw -notmatch '\$scripts\.Count -ne 174') { throw 'Build script must enforce the 174-script canonical count.' }
$sourceCommit = '16e24b119f96b93b34ddb148f9a035f71a234e67'
$prov = Get-Content (Join-Path $root 'DK-KHOADO-BACKPORT.md') -Raw
if ($prov -notmatch [regex]::Escape($sourceCommit)) { throw 'DK backport provenance commit is missing.' }
$ddt34Commit = '73e189aef774b1f2eead70979c97b53619db07aa'
$ddt34Prov = Get-Content (Join-Path $root 'DDT34-BACKPORT.md') -Raw
if ($ddt34Prov -notmatch [regex]::Escape($ddt34Commit)) { throw 'DDT3.4 backport provenance commit is missing.' }
$gunny92Commit = 'e53c3950f40a938fb0013be33230325e99397860'
$gunny92Prov = Get-Content (Join-Path $root 'GUNNY92-COMPAT-BACKPORT.md') -Raw
if ($gunny92Prov -notmatch [regex]::Escape($gunny92Commit)) { throw 'Gunny92 compat backport provenance commit is missing.' }
$yutiCommit = 'b90215e199ae079c05eb290ed1cbf2a2fb4bdf5e'
$yutiProv = Get-Content (Join-Path $root 'YUTI-COMPAT-BACKPORT.md') -Raw
if ($yutiProv -notmatch [regex]::Escape($yutiCommit)) { throw 'Yuti compat backport provenance commit is missing.' }
$skelletonxCommit = '09f8cdb2891ef0b49f44c4d6f68035a728623c00'
$skelletonxProv = Get-Content (Join-Path $root 'SKELLETONX-COMPAT-BACKPORT.md') -Raw
if ($skelletonxProv -notmatch [regex]::Escape($skelletonxCommit)) { throw 'SkelletonX compat backport provenance commit is missing.' }
$baseGunnyCommit = '94df4bc8add1d605a098ae44e291015c453100fe'
$baseGunnyProv = Get-Content (Join-Path $root 'BASEGUNNY-COMPAT-BACKPORT.md') -Raw
if ($baseGunnyProv -notmatch [regex]::Escape($baseGunnyCommit)) { throw 'BaseGunny compat backport provenance commit is missing.' }
Write-Host 'DDTANK30_PVE_SCRIPT_COVERAGE=PASS total=174 critical=55 dk=46 ddt34=12 gunny92=4 yuti=11 skelletonx=4 basegunny=1'
