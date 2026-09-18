$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$map = Get-Content (Join-Path $root 'Game.Logic\Phy\Maps\Map.cs') -Raw
$player = Get-Content (Join-Path $root 'Game.Logic\Phy\Object\Player.cs') -Raw
$fall = Get-Content (Join-Path $root 'Game.Logic\Actions\LivingFallingAction.cs') -Raw

if ($map -notmatch 'HasCharacterSupport') { throw 'Missing deterministic terrain support helper.' }
if ($map -notmatch 'return left && right;') { throw 'One-sided edge support must not keep a character floating.' }
if ($map -match 'tx > _bound\.Width') { throw 'Walk bound check still accepts x == width.' }

$start = [regex]::Match($player, '(?s)public override void StartMoving\(int delay, int speed\).*?\n\s*}')
if (-not $start.Success) { throw 'Player delayed StartMoving override missing.' }
if ($start.Value -match 'm_x\s*=|m_y\s*=|FindYLine') { throw 'Player StartMoving must not teleport to the landing point.' }
if ($start.Value -notmatch 'base\.StartMoving\(delay, speed\)') { throw 'Player must delegate settling to Living.' }

if ($fall -notmatch 'previousTargetY') { throw 'Falling action must detect terrain changes while airborne.' }
if ($fall -notmatch 'FindYLineNotEmptyPoint\(m_toX, m_living\.Y\)') { throw 'Falling action must revalidate the authoritative landing point.' }
if ($fall -notmatch 'previousTargetY != m_toY') { throw 'Changed landing point must be resent to clients.' }

Write-Output 'TERRAIN_CHARACTER_SETTLE_SMOKE=PASS'
