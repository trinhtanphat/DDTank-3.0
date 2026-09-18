$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$adminRoot = Join-Path $root 'GameAdmin'

function Require([bool]$condition, [string]$message) {
    if (-not $condition) { throw "V30_ADMIN_DASHBOARD_SMOKE_FAIL: $message" }
}

$dashboardPage = Get-Content (Join-Path $adminRoot 'Admin\Dashboard.aspx') -Raw
$dashboardCode = Get-Content (Join-Path $adminRoot 'Admin\Dashboard.aspx.cs') -Raw
$playerPage = Get-Content (Join-Path $adminRoot 'Admin\PlayerTools.aspx') -Raw
$playerCode = Get-Content (Join-Path $adminRoot 'Admin\PlayerTools.aspx.cs') -Raw
$project = Get-Content (Join-Path $adminRoot 'AdminGunny.csproj') -Raw
$master = Get-Content (Join-Path $adminRoot 'Site.Master') -Raw
$config = Get-Content (Join-Path $adminRoot 'Web.config') -Raw
$deploy = Get-Content (Join-Path $root 'deploy\Deploy-DDTank30AdminVip.ps1') -Raw
$installer = Get-Content (Join-Path $root 'deploy\Install-DDTank30Web.ps1') -Raw
$loginPage = Get-Content (Join-Path $adminRoot 'Account\Login.aspx') -Raw
$loginCode = Get-Content (Join-Path $adminRoot 'Account\Login.aspx.cs') -Raw
$accountConfig = Get-Content (Join-Path $adminRoot 'Account\Web.config') -Raw

Require ($config -match 'Initial Catalog=Db_Tank_V30') 'source AdminGunny must target Db_Tank_V30'
Require ($dashboardPage -match 'Gunny 3\.0 Admin Dashboard') 'dashboard heading is missing'
Require ($dashboardPage -match 'Admin/PlayerTools\.aspx') 'dashboard quick link to player tools is missing'
Require ($dashboardPage -match 'Admin/sendMail5Item\.aspx') 'dashboard quick link to five-item mail is missing'
Require ($dashboardCode -match 'ConfigurationManager\.AppSettings\["conString"\]') 'dashboard must use the configured V30 connection'
Require ($dashboardCode -match 'Sys_Users_Detail') 'dashboard player counts are missing'
Require ($dashboardCode -match 'Sys_VIP_Info') 'dashboard VIP count is missing'
Require ($dashboardCode -match 'Sys_User_Field') 'dashboard farm count is missing'

Require ($playerPage -match 'Quản lý người chơi') 'player management UI is missing'
Require ($playerPage -match 'Ban tài khoản') 'ban action is missing'
Require ($playerPage -match 'Unban tài khoản') 'unban action is missing'
Require ($playerPage -match 'Kick khỏi game') 'manual kick action is missing'
Require ($playerCode -match 'WHERE NickName=@Lookup OR UserName=@Lookup') 'player lookup must be parameterized'
Require ($playerCode -match 'command\.Parameters\.Add\("@Lookup"') 'player lookup parameter binding is missing'
Require ($playerCode -match 'IsolationLevel\.Serializable') 'player mutation must be serializable'
Require ($playerCode -match 'PrepareOffline') 'player mutation must have offline preparation'
Require ($playerCode -match 'KitoffUser') 'online player must be kicked before mutation'
Require ($playerCode -match 'ForbidPlayerByUserID') 'ban/unban must use the game management contract'
Require ($playerCode -match 'UPDATE dbo\.Sys_Users_Detail WITH \(ROWLOCK\)') 'player update must use a row-scoped update'
Require ($playerCode -match '@Grade') 'player update must use SQL parameters'

Require ($project -match 'Admin\\Dashboard\.aspx') 'dashboard is not included in AdminGunny project'
Require ($project -match 'Admin\\PlayerTools\.aspx') 'player tools are not included in AdminGunny project'
Require ($master -match 'Admin/Dashboard\.aspx') 'dashboard is not linked from source navigation'
Require ($master -match 'Admin/PlayerTools\.aspx') 'player tools are not linked from source navigation'

Require ($deploy -match 'SqlDataProvider\\SqlDataProvider\.csproj') 'deploy must rebuild SqlDataProvider before AdminGunny'
Require ($deploy -match 'Bussiness\\Bussiness\.csproj') 'deploy must rebuild Bussiness before AdminGunny'
Require ($deploy -match 'AdminGunny\.csproj') 'managed deploy must build GameAdmin'
Require ($deploy -match 'Admin\\Dashboard\.aspx') 'deploy must overlay Dashboard.aspx'
Require ($deploy -match 'Admin\\PlayerTools\.aspx') 'deploy must overlay PlayerTools.aspx'
Require ($deploy -match 'backups\\admingunny-managed-') 'deploy must back up the live managed surface'
Require ($deploy -match '~/Admin/Dashboard\.aspx') 'deploy must patch production dashboard navigation'
Require ($deploy -match '~/Admin/PlayerTools\.aspx') 'deploy must patch production player navigation'
Require ($deploy -match 'Initial Catalog=Db_Tank_V30') 'deploy must verify the live V30 database binding'
Require ($loginPage -match 'CommandName="Login"') 'login submit must use the Login control command'
Require ($loginPage -match 'OnAuthenticate="LoginUser_Authenticate"') 'login control must use the custom Authenticate handler'
Require ($loginCode -match 'LoginUser_Authenticate') 'custom Authenticate handler is missing'
Require ($loginCode -match 'adminPasswordHash') 'login must prefer a password hash'
Require ($loginCode -match 'SHA256\.Create') 'login hash verification is missing'
Require ($loginCode -match 'SlowEquals') 'login hash comparison helper is missing'
Require ($config -notmatch 'key="adminPassword"\s+value="password"') 'source config must not ship the weak default password'
Require ($accountConfig -match 'deny users="\?"') 'account folder must deny anonymous access except login'
Require ($deploy -match 'Account\\Login\.aspx') 'deploy must install the login page'
Require ($deploy -match 'Account\\Web\.config') 'deploy must install account authorization config'
Require ($deploy -match 'RandomNumberGenerator') 'deploy must generate a strong first-run password'
Require ($deploy -match 'adminPasswordSalt') 'deploy must persist a salt'
Require ($deploy -match 'adminPasswordHash') 'deploy must persist a hash'
Require ($deploy -match 'SetAccessRuleProtection') 'generated credential ACL must be restricted'
Require ($deploy -match 'credentialAcl.SetAccessRuleProtection') 'deploy must re-apply the restricted credential ACL on every run'
Require ($deploy -match 'authentication.+Forms') 'deploy must enable Forms Authentication'
Require ($deploy -match 'denyAnonymous') 'deploy must deny anonymous access'
Require ($deploy -match 'AdminGunny-V30\.txt') 'deploy must persist generated credential outside the webroot'
Require ($deploy -match "Relative='Web\.config'") 'deploy must back up live Web.config before mutation'
Require ($installer -match 'Deploy-DDTank30AdminVip\.ps1') 'web installer must retain managed admin deployment'

Write-Host 'V30_ADMIN_DASHBOARD_SMOKE=PASS'
