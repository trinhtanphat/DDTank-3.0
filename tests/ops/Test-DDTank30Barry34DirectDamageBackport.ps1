$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$living = Get-Content (Join-Path $repo 'Game.Logic\Phy\Object\Living.cs') -Raw
if ($living -notmatch 'public bool RangeAttacking\(int fx, int tx, string action, int delay, bool directDamage\)') { throw 'Missing directDamage overload.' }
if ($living -notmatch 'new LivingRangeAttackingAction\(this, fx, tx, action, delay, directDamage, null\)') { throw 'directDamage flag is not forwarded.' }
$action = Get-Content (Join-Path $repo 'Game.Logic\Actions\LivingRangeAttackingAction.cs') -Raw
foreach ($need in @('private bool m_directDamage;', 'delay, false, players', 'm_directDamage = directDamage;', 'if \(!m_directDamage\)')) {
  if ($action -notmatch $need) { throw "Action contract missing: $need" }
}
if ($action -notmatch 'damage = damage \* \(1 - distance / Math\.Abs\(m_tx - m_fx\) / 4\);') { throw 'Distance attenuation was not preserved.' }
foreach ($name in @('FiveHardSecondNpc.cs','FiveNormalSecondNpc.cs','FiveTerrorSecondNpc.cs')) {
  $path = Join-Path $repo ('GameServerScript\AI\NPC\DragonWar\'+$name)
  if (-not (Test-Path $path)) { throw "Missing script: $name" }
  $raw=Get-Content $path -Raw
  if ($raw -match 'directDamage\s*:') { throw "C#4 named argument remains: $name" }
  if ($raw -notmatch 'RangeAttacking\([^;]+, true\);') { throw "Positional directDamage flag missing: $name" }
}
$prov=Get-Content (Join-Path $repo 'GameServerScript\BARRY34-DIRECTDAMAGE-BACKPORT.md') -Raw
if ($prov -notmatch '73e189aef774b1f2eead70979c97b53619db07aa') { throw 'Barry34 source provenance missing.' }
if ($prov -notmatch '3f5b4866572823dee7bd01c86c5488948ebd7b82') { throw 'DDT3.8 semantics provenance missing.' }
Write-Host 'DDTANK30_BARRY34_DIRECTDAMAGE=PASS scripts=3 default=attenuated direct=true=no-distance-attenuation'
