$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$gameMgr = Get-Content (Join-Path $repo 'Fighting.Server\Games\GameMgr.cs') -Raw
$mapMgr = Get-Content (Join-Path $repo 'Game.Logic\MapMgr.cs') -Raw

function Require([bool]$condition, [string]$message) {
    if (-not $condition) { throw $message }
}

Require ($gameMgr -match 'ProxyPlayer proxy = p\.PlayerDetail as ProxyPlayer;') 'start message must use a checked ProxyPlayer cast'
Require ($gameMgr -match 'if \(proxy == null\)\s*continue;') 'synthetic bot must bypass ProxyPlayer-only Rate/Buffers'
Require ($gameMgr -notmatch '\(p\.PlayerDetail as ProxyPlayer\)\.Rate') 'unsafe ProxyPlayer Rate dereference remains'
Require ($gameMgr -notmatch '\(p\.PlayerDetail as ProxyPlayer\)\.Buffers') 'unsafe ProxyPlayer Buffers dereference remains'
Require ($gameMgr -match 'MapMgr\.GetMapIndex\(mapIndex, \(byte\)roomType, m_serverId, requiredPerTeam\)') 'PvP game creation must request spawn-capacity-aware map selection'
Require ($gameMgr -match 'game\.Prepare\(\);\s*SendStartMessage\(game\);\s*lock \(m_games\)') 'battle game must not enter GameMgr before prepare/start message succeeds'
Require ($mapMgr -match 'HasPvpSpawnCapacity') 'PvP spawn-capacity helper is missing'
Require ($mapMgr -match 'points\.PosX\.Count >= requiredPerTeam') 'team 1 spawn capacity is not checked'
Require ($mapMgr -match 'points\.PosX1\.Count >= requiredPerTeam') 'team 2 spawn capacity is not checked'
Require ($mapMgr -match 'No PvP map has at least') 'no explicit failure exists for exhausted PvP map pool'

Write-Host 'DDTANK30_PVP_READY_START_GUARD=PASS'
