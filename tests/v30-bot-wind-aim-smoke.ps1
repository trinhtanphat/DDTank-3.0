$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$baseGame = Get-Content (Join-Path $root 'Game.Logic\BaseGame.cs') -Raw
$living = Get-Content (Join-Path $root 'Game.Logic\Phy\Object\Living.cs') -Raw
$shootAction = Get-Content (Join-Path $root 'Game.Logic\Actions\LivingShootAction.cs') -Raw
$bot = Get-Content (Join-Path $root 'Fighting.Server\GameObjects\BotProxyPlayer.cs') -Raw

function Require([bool]$ok, [string]$message) {
    if (-not $ok) { throw $message }
}

Require ($baseGame -match 'internal static int EncodeWind\(float wind\)') 'shared wind encoder missing'
Require ($baseGame -match 'Math\.Round\(wind \* 10f, MidpointRounding\.AwayFromZero\)') 'wind encoder precision contract missing'
Require ($baseGame -match 'm_random\.Next\(-40, 41\)') 'wind target range contract missing'
Require ($baseGame -match 'pkg\.WriteBoolean\(EncodeWind\(game\.Wind\) >= 0\)') 'TURN wind direction contract missing'
Require ($living -match 'float wf = map\.wind \* ballInfo\.Wind;') 'ballistics must apply wind coefficient'
Require ($living -match 'Direction = x >= initialShootPoint\.X \? 1 : -1;') 'NPC solver must face target before solving'
Require ($living -match 't \+= 0\.10f') 'fine flight-time search missing'
Require ($living -match 'Math\.Atan2\(vy, vx\)') 'quadrant-safe angle missing'
Require ($living -match 'pkg\.WriteByte\(\(byte\)eTankCmdType\.FIRE\);\s*pkg\.WriteInt\(bombCount\);') 'FIRE packet must keep the legacy Gunny 3.0 bomb-count header'
Require ($living -notmatch 'eTankCmdType\.FIRE\);\s*int wind = BaseGame\.EncodeWind') 'FIRE packet must not prepend TURN/VANE wind fields that desync the client parser'
Require ($shootAction -notmatch 'm_living is SimpleBoss') 'ShootPoint solver remains boss-only'
Require ($shootAction -match 'm_force == 0 && m_angle == 0 && m_minTime < m_maxTime') 'target-point solver guard missing'
Require ($bot -match 'Math\.Abs\(player\.Game\.Wind\)') 'bot wind adaptation missing'
Require ($bot -match 'ScheduleRemainingShots\(PVPGame game, Player player\)') 'bot multishot scheduler missing'
Require ($bot -match 'player\.ShootCount <= 0') 'bot ammo guard missing'
Require ($bot -match 'CallFuction\(new LivingCallBack\(delegate') 'delayed follow-up missing'
Require ($bot -match '\}\), 650\);') 'follow-up cadence missing'

Write-Host 'DDTANK30_BOT_WIND_AIM_SMOKE=PASS'
