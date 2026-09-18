$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$adminRoot = Join-Path $root 'GameAdmin'

function Require([bool]$condition, [string]$message) {
    if (-not $condition) { throw "V30_ADMIN_VIP20_SMOKE_FAIL: $message" }
}

$page = Get-Content (Join-Path $adminRoot 'Admin\SetVip.aspx') -Raw
$code = Get-Content (Join-Path $adminRoot 'Admin\SetVip.aspx.cs') -Raw
$project = Get-Content (Join-Path $adminRoot 'AdminGunny.csproj') -Raw
$master = Get-Content (Join-Path $adminRoot 'Site.Master') -Raw

Require ($code -match 'MaxVipLevel\s*=\s*20') 'max VIP must be 20'
Require ($code -match '7800000') 'VIP20 EXP floor is missing'
Require ($code -match 'GetVipExpFloor\(target\)') 'selected VIP must receive its cumulative EXP floor'
Require ($code -match 'UPDLOCK,HOLDLOCK,ROWLOCK') 'VIP mutation must lock the row'
Require ($code -match 'IsolationLevel\.Serializable') 'VIP mutation must be serializable'
Require ($code -match 'KitoffUser') 'online player must be kicked before mutation'
Require ($code -match 'for \(int vip = 1; vip <= MaxVipLevel; vip\+\+\)') 'target dropdown must include VIP20'
Require ($code -match 'QuickVip20Button_Click') 'VIP20 quick action is missing'
Require ($code -notmatch 'VIPExp=0') 'admin must not blindly reset persisted VIP EXP to zero'
Require ($page -match 'VIP 20 MAX') 'VIP20 quick button is missing'
Require ($page -match 'VIP EXP') 'VIP EXP snapshot is missing'
Require ($project -match 'Admin\\SetVip\.aspx') 'VIP page is not included in AdminGunny project'
Require ($master -match 'Admin/SetVip\.aspx') 'VIP page is not linked from navigation'

Write-Host 'V30_ADMIN_VIP20_SMOKE=PASS'
