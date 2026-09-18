$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Require([bool]$condition, [string]$message) {
    if (-not $condition) { throw "V30_VIP20_SMOKE_FAIL: $message" }
}

$packet = Get-Content (Join-Path $root 'Game.Server\Packets\Server\AbstractPacketLib.cs') -Raw
$migration = Get-Content (Join-Path $root 'database\20260918_v30_vip20.sql') -Raw

Require ($packet -match 'LoadVipSnapshot') '3.0 login packet must load persisted VIP state'
Require ($packet -match 'FROM dbo\.Sys_VIP_Info WHERE UserID=@UserID') 'VIP lookup must be scoped to authenticated user ID'
Require ($packet -match 'pkg\.WriteBoolean\(vip\.IsVip\)') 'login packet must send persisted VIP enabled state'
Require ($packet -match 'pkg\.WriteInt\(vip\.Level\)') 'login packet must send persisted VIP level'
Require ($packet -match 'pkg\.WriteInt\(vip\.Exp\)') 'login packet must send persisted VIP EXP'
Require ($packet -match 'pkg\.WriteDateTime\(vip\.ExpireDay\)') 'login packet must send persisted VIP expiry'
Require ($packet -match 'Math\.Max\(exp, GetVipFloor\(level\)\)') 'VIP EXP must be normalized to the current level floor'
Require ($packet -notmatch 'pkg\.WriteInt\(50000\)') 'legacy fake VIP EXP must be removed'
Require ($migration -match "VIPMaxLevel','20") '3.0 migration must advertise VIP20'
Require ($migration -match 'CREATE TABLE dbo\.Sys_VIP_Info') '3.0 migration must create VIP storage when missing'
Require ($migration -match '7800000') 'VIP20 EXP floor is missing'
Require ($migration -match 'CREATE OR ALTER PROCEDURE dbo\.SP_VIPRenewal_Single') 'safe renewal procedure is missing'
Require ($migration -notmatch 'SET\s+VIPLevel\s*=\s*1') 'renewal must not reset an existing VIP level'

Write-Host 'V30_VIP20_SMOKE=PASS'
