param(
    [Parameter(Mandatory=$true)][string]$RepoRoot,
    [Parameter(Mandatory=$true)][string]$WebRoot,
    [Parameter(Mandatory=$true)][string]$VSToolsPath
)

$ErrorActionPreference = 'Stop'
$msbuild = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe'
$projectDir = Join-Path $RepoRoot 'GameAdmin'
$sqlProject = Join-Path $RepoRoot 'SqlDataProvider\SqlDataProvider.csproj'
$businessProject = Join-Path $RepoRoot 'Bussiness\Bussiness.csproj'
$project = Join-Path $projectDir 'AdminGunny.csproj'
$webTargets = Join-Path $VSToolsPath 'WebApplications\Microsoft.WebApplication.targets'
$adminRoot = Join-Path $WebRoot 'admingunny'
$dllSource = Join-Path $projectDir 'bin\WebApplication1.dll'
$dllTarget = Join-Path $adminRoot 'bin\WebApplication1.dll'
$master = Join-Path $adminRoot 'Site.Master'
$liveConfig = Join-Path $adminRoot 'Web.config'

$managedPages = @(
    @{ Relative='Admin\Dashboard.aspx'; Source=(Join-Path $projectDir 'Admin\Dashboard.aspx'); Target=(Join-Path $adminRoot 'Admin\Dashboard.aspx') },
    @{ Relative='Admin\PlayerTools.aspx'; Source=(Join-Path $projectDir 'Admin\PlayerTools.aspx'); Target=(Join-Path $adminRoot 'Admin\PlayerTools.aspx') },
    @{ Relative='Admin\SetVip.aspx'; Source=(Join-Path $projectDir 'Admin\SetVip.aspx'); Target=(Join-Path $adminRoot 'Admin\SetVip.aspx') },
    @{ Relative='Account\Login.aspx'; Source=(Join-Path $projectDir 'Account\Login.aspx'); Target=(Join-Path $adminRoot 'Account\Login.aspx') },
    @{ Relative='Account\Web.config'; Source=(Join-Path $projectDir 'Account\Web.config'); Target=(Join-Path $adminRoot 'Account\Web.config') }
)

foreach ($required in @($msbuild,$sqlProject,$businessProject,$project,$webTargets,$adminRoot,$master,$liveConfig)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing AdminGunny managed deploy prerequisite: $required" }
}
foreach ($page in $managedPages) {
    if (-not (Test-Path -LiteralPath $page.Source -PathType Leaf)) { throw "Missing AdminGunny managed page: $($page.Source)" }
}

& $msbuild $sqlProject /t:Rebuild /p:Configuration=Release /m:1 /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw "SqlDataProvider.csproj build failed: $LASTEXITCODE" }

& $msbuild $businessProject /t:Rebuild /p:Configuration=Release /m:1 /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw "Bussiness.csproj build failed: $LASTEXITCODE" }

& $msbuild $project /t:Rebuild /p:Configuration=Release "/p:VSToolsPath=$VSToolsPath" /m:1 /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw "AdminGunny.csproj build failed: $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $dllSource -PathType Leaf)) { throw "AdminGunny build output missing: $dllSource" }

function Copy-RequiredFile([string]$Source,[string]$Destination) {
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Required source file missing: $Source" }
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination -Parent) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) { throw "Deploy copy failed: $Destination" }
}

function Ensure-AsciiLineAfterAnchor([string]$Path,[string]$Presence,[string]$Anchor,[string]$Line) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $ascii = [Text.Encoding]::ASCII
    $shadow = $ascii.GetString($bytes)
    $presenceCount = [regex]::Matches($shadow,[regex]::Escape($Presence)).Count
    if ($presenceCount -eq 1) { return $false }
    if ($presenceCount -gt 1) { throw "Duplicate AdminGunny navigation entry '$Presence' in $Path" }
    $index = $shadow.IndexOf($Anchor,[StringComparison]::Ordinal)
    if ($index -lt 0) { throw "AdminGunny production navigation anchor '$Anchor' not found in $Path" }
    $insertAt = $index + $Anchor.Length
    $tail = $shadow.Substring($insertAt)
    $newline = if ($tail.StartsWith("`r`n")) { "`r`n" } elseif ($tail.StartsWith("`n")) { "`n" } else { [Environment]::NewLine }
    $insert = $ascii.GetBytes($newline + $Line)
    $combined = New-Object byte[] ($bytes.Length + $insert.Length)
    [Buffer]::BlockCopy($bytes,0,$combined,0,$insertAt)
    [Buffer]::BlockCopy($insert,0,$combined,$insertAt,$insert.Length)
    [Buffer]::BlockCopy($bytes,$insertAt,$combined,$insertAt+$insert.Length,$bytes.Length-$insertAt)
    [IO.File]::WriteAllBytes($Path,$combined)
    $verify = $ascii.GetString([IO.File]::ReadAllBytes($Path))
    if ([regex]::Matches($verify,[regex]::Escape($Presence)).Count -ne 1) {
        throw "AdminGunny navigation verification failed for '$Presence' in $Path"
    }
    return $true
}

$backupRoot = Join-Path (Split-Path $WebRoot -Parent) ('backups\admingunny-managed-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

foreach ($entry in @(
    @{ Path=$master; Relative='Site.Master' },
    @{ Path=$liveConfig; Relative='Web.config' },
    @{ Path=$dllTarget; Relative='bin\WebApplication1.dll' }
)) {
    if (Test-Path -LiteralPath $entry.Path) {
        $backupTarget = Join-Path $backupRoot $entry.Relative
        New-Item -ItemType Directory -Force -Path (Split-Path $backupTarget -Parent) | Out-Null
        Copy-Item -LiteralPath $entry.Path -Destination $backupTarget -Force
    }
}
foreach ($page in $managedPages) {
    if (Test-Path -LiteralPath $page.Target) {
        $backupTarget = Join-Path $backupRoot $page.Relative
        New-Item -ItemType Directory -Force -Path (Split-Path $backupTarget -Parent) | Out-Null
        Copy-Item -LiteralPath $page.Target -Destination $backupTarget -Force
    }
}

foreach ($page in $managedPages) {
    Copy-RequiredFile $page.Source $page.Target
}
Copy-RequiredFile $dllSource $dllTarget

$sendMailAnchor = '<asp:MenuItem NavigateUrl="~/Admin/sendMail5Item.aspx" Text="SendMail"/>'
$dashboardLine = '                        <asp:MenuItem NavigateUrl="~/Admin/Dashboard.aspx" Text="Dashboard V30"/>'
$playerLine = '                        <asp:MenuItem NavigateUrl="~/Admin/PlayerTools.aspx" Text="Players V30"/>'
$vipLine = '                        <asp:MenuItem NavigateUrl="~/Admin/SetVip.aspx" Text="VIP 1-20"/>'

$dashboardPatched = Ensure-AsciiLineAfterAnchor $master '~/Admin/Dashboard.aspx' $sendMailAnchor $dashboardLine
$playerPatched = Ensure-AsciiLineAfterAnchor $master '~/Admin/PlayerTools.aspx' $dashboardLine.Trim() $playerLine
$vipPatched = Ensure-AsciiLineAfterAnchor $master '~/Admin/SetVip.aspx' $playerLine.Trim() $vipLine

$masterShadow = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($master))
foreach ($presence in @('~/Admin/Dashboard.aspx','~/Admin/PlayerTools.aspx','~/Admin/SetVip.aspx')) {
    if ([regex]::Matches($masterShadow,[regex]::Escape($presence)).Count -ne 1) {
        throw "AdminGunny navigation is not exactly-once after deploy: $presence"
    }
}


function Set-AppSettingValue([xml]$Xml,[string]$Key,[string]$Value) {
    $appSettings = $Xml.SelectSingleNode('/configuration/appSettings')
    if ($null -eq $appSettings) {
        $appSettings = $Xml.CreateElement('appSettings')
        [void]$Xml.configuration.PrependChild($appSettings)
    }
    $node = $appSettings.SelectSingleNode("add[@key='" + $Key + "']")
    if ($null -eq $node) {
        $node = $Xml.CreateElement('add')
        $node.SetAttribute('key',$Key)
        [void]$appSettings.AppendChild($node)
    }
    $node.SetAttribute('value',$Value)
}

[xml]$liveXml = Get-Content -LiteralPath $liveConfig -Raw
$appSettingsNode = $liveXml.SelectSingleNode('/configuration/appSettings')
$adminUserNode = if ($null -ne $appSettingsNode) { $appSettingsNode.SelectSingleNode("add[@key='adminUser']") } else { $null }
$adminUser = if ($null -ne $adminUserNode -and -not [string]::IsNullOrWhiteSpace($adminUserNode.GetAttribute('value'))) {
    $adminUserNode.GetAttribute('value')
} else {
    'admin'
}
Set-AppSettingValue $liveXml 'adminUser' $adminUser

$saltNode = $liveXml.SelectSingleNode("/configuration/appSettings/add[@key='adminPasswordSalt']")
$hashNode = $liveXml.SelectSingleNode("/configuration/appSettings/add[@key='adminPasswordHash']")
$adminSalt = if ($null -ne $saltNode) { $saltNode.GetAttribute('value') } else { '' }
$adminHash = if ($null -ne $hashNode) { $hashNode.GetAttribute('value') } else { '' }
$generatedCredential = $false
$credentialPath = Join-Path (Split-Path $WebRoot -Parent) 'secrets\AdminGunny-V30.txt'

if ([string]::IsNullOrWhiteSpace($adminSalt) -or
    [string]::IsNullOrWhiteSpace($adminHash) -or
    -not (Test-Path -LiteralPath $credentialPath -PathType Leaf)) {
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $passwordBytes = New-Object byte[] 18
        $saltBytes = New-Object byte[] 18
        $rng.GetBytes($passwordBytes)
        $rng.GetBytes($saltBytes)
    } finally {
        $rng.Dispose()
    }

    $generatedPassword = [Convert]::ToBase64String($passwordBytes).TrimEnd('=').Replace('+','-').Replace('/','_')
    $adminSalt = [Convert]::ToBase64String($saltBytes)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($adminSalt + ':' + $generatedPassword))
        $adminHash = [Convert]::ToBase64String($hashBytes)
    } finally {
        $sha.Dispose()
    }

    Set-AppSettingValue $liveXml 'adminPasswordSalt' $adminSalt
    Set-AppSettingValue $liveXml 'adminPasswordHash' $adminHash

    New-Item -ItemType Directory -Force -Path (Split-Path $credentialPath -Parent) | Out-Null
    $credentialText = 'username=' + $adminUser + [Environment]::NewLine +
                      'password=' + $generatedPassword + [Environment]::NewLine +
                      'created=' + (Get-Date).ToString('o') + [Environment]::NewLine
    [IO.File]::WriteAllText($credentialPath,$credentialText,(New-Object Text.UTF8Encoding($false)))

    $acl = New-Object Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true,$false)
    foreach ($sidText in @('S-1-5-18','S-1-5-32-544')) {
        $sid = New-Object Security.Principal.SecurityIdentifier($sidText)
        $rule = New-Object Security.AccessControl.FileSystemAccessRule(
            $sid,
            [Security.AccessControl.FileSystemRights]::FullControl,
            [Security.AccessControl.AccessControlType]::Allow)
        $acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $credentialPath -AclObject $acl
    $generatedCredential = $true
}

# Re-apply the restrictive ACL on every deploy so a later manual permission change
# cannot accidentally expose the generated administrator credential.
if (-not (Test-Path -LiteralPath $credentialPath -PathType Leaf)) {
    throw 'AdminGunny credential file is missing after credential provisioning.'
}
$credentialAcl = New-Object Security.AccessControl.FileSecurity
$credentialAcl.SetAccessRuleProtection($true,$false)
foreach ($sidText in @('S-1-5-18','S-1-5-32-544')) {
    $sid = New-Object Security.Principal.SecurityIdentifier($sidText)
    $rule = New-Object Security.AccessControl.FileSystemAccessRule(
        $sid,
        [Security.AccessControl.FileSystemRights]::FullControl,
        [Security.AccessControl.AccessControlType]::Allow)
    $credentialAcl.AddAccessRule($rule)
}
Set-Acl -LiteralPath $credentialPath -AclObject $credentialAcl

# Remove legacy plaintext password if present.
$legacyPasswordNode = $liveXml.SelectSingleNode("/configuration/appSettings/add[@key='adminPassword']")
if ($null -ne $legacyPasswordNode) {
    [void]$legacyPasswordNode.ParentNode.RemoveChild($legacyPasswordNode)
}

$systemWeb = $liveXml.SelectSingleNode('/configuration/system.web')
if ($null -eq $systemWeb) {
    $systemWeb = $liveXml.CreateElement('system.web')
    [void]$liveXml.configuration.AppendChild($systemWeb)
}

$authentication = $systemWeb.SelectSingleNode('authentication')
if ($null -eq $authentication) {
    $authentication = $liveXml.CreateElement('authentication')
    [void]$systemWeb.AppendChild($authentication)
}
$authentication.SetAttribute('mode','Forms')
$forms = $authentication.SelectSingleNode('forms')
if ($null -eq $forms) {
    $forms = $liveXml.CreateElement('forms')
    [void]$authentication.AppendChild($forms)
}
$forms.SetAttribute('loginUrl','~/Account/Login.aspx')
$forms.SetAttribute('timeout','60')
$forms.SetAttribute('slidingExpiration','true')
$forms.SetAttribute('protection','All')

$authorization = $systemWeb.SelectSingleNode('authorization')
if ($null -eq $authorization) {
    $authorization = $liveXml.CreateElement('authorization')
    [void]$systemWeb.AppendChild($authorization)
}
$authorization.RemoveAll()
$denyAnonymous = $liveXml.CreateElement('deny')
$denyAnonymous.SetAttribute('users','?')
[void]$authorization.AppendChild($denyAnonymous)

# Explicitly allow the login page even though the application root denies anonymous users.
$loginLocation = $liveXml.SelectSingleNode("/configuration/location[@path='Account/Login.aspx']")
if ($null -eq $loginLocation) {
    $loginLocation = $liveXml.CreateElement('location')
    $loginLocation.SetAttribute('path','Account/Login.aspx')
    $locSystemWeb = $liveXml.CreateElement('system.web')
    $locAuthorization = $liveXml.CreateElement('authorization')
    $clearRules = $liveXml.CreateElement('clear')
    $allowAll = $liveXml.CreateElement('allow')
    $allowAll.SetAttribute('users','*')
    [void]$locAuthorization.AppendChild($clearRules)
    [void]$locAuthorization.AppendChild($allowAll)
    [void]$locSystemWeb.AppendChild($locAuthorization)
    [void]$loginLocation.AppendChild($locSystemWeb)
    [void]$liveXml.configuration.PrependChild($loginLocation)
}

$liveXml.Save($liveConfig)

$configRaw = Get-Content -LiteralPath $liveConfig -Raw
if ($configRaw -notmatch 'Initial Catalog=Db_Tank_V30') {
    throw 'AdminGunny live Web.config is not bound to Db_Tank_V30.'
}
if ($configRaw -notmatch 'authentication mode="Forms"' -or
    $configRaw -notmatch 'loginUrl="~/Account/Login.aspx"' -or
    $configRaw -notmatch 'deny users="\?"' -or
    $configRaw -match 'key="adminPassword"') {
    throw 'AdminGunny authentication hardening verification failed.'
}
if (-not (Test-Path -LiteralPath $credentialPath -PathType Leaf) -and $generatedCredential) {
    throw 'Generated AdminGunny credential file is missing.'
}

$pageHashes = @{}
foreach ($page in $managedPages) {
    $pageHashes[$page.Relative] = (Get-FileHash -LiteralPath $page.Target -Algorithm SHA256).Hash
}
$dllHash = (Get-FileHash -LiteralPath $dllTarget -Algorithm SHA256).Hash

Write-Host ("DDTANK30_ADMIN_MANAGED_DEPLOY=PASS dashboardSha={0} playerToolsSha={1} vipSha={2} dllSha={3} navDashboard={4} navPlayer={5} navVip={6} backup={7} credentialGenerated={8} credentialPath={9}" -f
    $pageHashes['Admin\Dashboard.aspx'],
    $pageHashes['Admin\PlayerTools.aspx'],
    $pageHashes['Admin\SetVip.aspx'],
    $dllHash,
    $dashboardPatched,
    $playerPatched,
    $vipPatched,
    $backupRoot,
    $generatedCredential,
    $credentialPath)
