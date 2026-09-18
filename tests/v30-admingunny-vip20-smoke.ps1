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
$deploy = Get-Content (Join-Path $root 'deploy\Deploy-DDTank30AdminVip.ps1') -Raw
$installer = Get-Content (Join-Path $root 'deploy\Install-DDTank30Web.ps1') -Raw

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
Require ($master -match 'Admin/SetVip\.aspx') 'VIP page is not linked from source navigation'
Require ($project -match '<VSToolsPath Condition=') 'AdminGunny must allow vendored WebApplication targets'
Require ($project -match '\$\(VSToolsPath\)\\WebApplications\\Microsoft\.WebApplication\.targets') 'AdminGunny must import through VSToolsPath'
Require ($deploy -match 'AdminGunny\.csproj') 'managed deploy must build GameAdmin'
Require ($deploy -match 'Admin\\SetVip\.aspx') 'managed deploy must overlay SetVip.aspx'
Require ($deploy -match 'bin\\WebApplication1\.dll') 'managed deploy must overlay WebApplication1.dll'
Require ($deploy -match 'ReadAllBytes') 'production master must still be patched without re-encoding it'
Require ($deploy -match 'sendMail5Item\.aspx') 'managed deploy must anchor to production navigation'
Require ($deploy -match '~/Admin/SetVip\.aspx') 'managed deploy must keep the VIP navigation link'
Require ($deploy -match 'Initial Catalog=Db_Tank_V30') 'managed deploy must reject a wrong AdminGunny database binding'
Require ($installer -match 'Deploy-DDTank30AdminVip\.ps1') 'web installer must invoke the managed admin deploy contract'

Write-Host 'V30_ADMIN_VIP20_SMOKE=PASS'
