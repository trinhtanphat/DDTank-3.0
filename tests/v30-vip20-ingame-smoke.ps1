$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Require([bool]$condition, [string]$message) {
    if (-not $condition) { throw "V30_VIP20_INGAME_SMOKE_FAIL: $message" }
}

$enum = Get-Content (Join-Path $root 'Game.Server\Packets\ePackageType.cs') -Raw
$handler = Get-Content (Join-Path $root 'Game.Server\Packets\Client\OpenVipHandler.cs') -Raw
$project = Get-Content (Join-Path $root 'Game.Server\Game.Server.csproj') -Raw

Require ($enum -match 'VIP_RENEWAL\s*=\s*0x5c') 'packet 92 must be reserved for VIP renewal'
Require ($handler -match 'String\.Equals\(requestedNickName, client\.Player\.PlayerCharacter\.NickName') 'renewal must be scoped to the authenticated player'
Require ($handler -match 'packet\.DataLeft > 0 \? packet\.ReadByte\(\) : PayWithXu') 'legacy clients must default to Xu and new clients may select payment mode'
Require ($handler -match 'PayWithGold') 'Gold payment mode is missing'
Require ($handler -match 'GoldPerXu\s*=\s*1000') 'Gold conversion constant is missing'
Require ($handler -match 'FindShopbyTemplatID\(VipTemplateId\)') 'VIP price must come from template 11992'
Require ($handler -match 'item\.AUnit == 31') '1-month shop price mapping is missing'
Require ($handler -match 'item\.BUnit == 93') '3-month shop price mapping is missing'
Require ($handler -match 'item\.CUnit == 365') '1-year shop price mapping is missing'
Require ($handler -match 'IsolationLevel\.Serializable') 'renewal transaction must be serializable'
Require ($handler -match 'UPDATE dbo\.Sys_Users_Detail SET') 'currency charge must be persisted in the same DB transaction'
Require ($handler -match 'SP_VIPRenewal_Single') 'safe VIP renewal procedure must be used'
Require ($handler -match 'renewalDays \* 10') 'renewal must add VIP EXP'
Require ($handler -match 'MaxVipLevel\s*=\s*20') 'VIP progression must support level 20'
Require ($handler -match '7800000') 'VIP20 EXP floor is missing'
Require ($handler -match 'SendVipState') 'client must receive updated VIP state immediately'
Require ($project -match 'Packets\\Client\\OpenVipHandler\.cs') 'VIP renewal handler is not compiled by Game.Server'

Write-Host 'V30_VIP20_INGAME_SMOKE=PASS'
