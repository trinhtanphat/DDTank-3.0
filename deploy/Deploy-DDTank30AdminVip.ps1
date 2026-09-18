param(
    [Parameter(Mandatory=$true)][string]$RepoRoot,
    [Parameter(Mandatory=$true)][string]$WebRoot,
    [Parameter(Mandatory=$true)][string]$VSToolsPath
)

$ErrorActionPreference = 'Stop'
$msbuild = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe'
$projectDir = Join-Path $RepoRoot 'GameAdmin'
$project = Join-Path $projectDir 'AdminGunny.csproj'
$webTargets = Join-Path $VSToolsPath 'WebApplications\Microsoft.WebApplication.targets'
$adminRoot = Join-Path $WebRoot 'admingunny'
$pageSource = Join-Path $projectDir 'Admin\SetVip.aspx'
$dllSource = Join-Path $projectDir 'bin\WebApplication1.dll'
$pageTarget = Join-Path $adminRoot 'Admin\SetVip.aspx'
$dllTarget = Join-Path $adminRoot 'bin\WebApplication1.dll'
$master = Join-Path $adminRoot 'Site.Master'

foreach ($required in @($msbuild,$project,$webTargets,$adminRoot,$pageSource,$master)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing AdminGunny VIP20 deploy prerequisite: $required" }
}

& $msbuild $project /t:Rebuild /p:Configuration=Release "/p:VSToolsPath=$VSToolsPath" /m:1 /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw "AdminGunny.csproj build failed: $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $dllSource)) { throw "AdminGunny build output missing: $dllSource" }

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
    if ($presenceCount -gt 1) { throw "Duplicate AdminGunny VIP navigation entries in $Path" }
    $index = $shadow.IndexOf($Anchor,[StringComparison]::Ordinal)
    if ($index -lt 0) { throw "AdminGunny production navigation anchor not found in $Path" }
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
    if ([regex]::Matches($verify,[regex]::Escape($Presence)).Count -ne 1) { throw "AdminGunny VIP navigation verification failed in $Path" }
    return $true
}

$backupRoot = Join-Path (Split-Path $WebRoot -Parent) ('backups\admingunny-vip20-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
foreach ($entry in @(
    @{ Path=$master; Name='Site.Master' },
    @{ Path=$pageTarget; Name='SetVip.aspx' },
    @{ Path=$dllTarget; Name='WebApplication1.dll' }
)) {
    if (Test-Path -LiteralPath $entry.Path) { Copy-Item -LiteralPath $entry.Path -Destination (Join-Path $backupRoot $entry.Name) -Force }
}

Copy-RequiredFile $pageSource $pageTarget
Copy-RequiredFile $dllSource $dllTarget
$anchor = '<asp:MenuItem NavigateUrl="~/Admin/sendMail5Item.aspx" Text="SendMail"/>'
$vipLine = '                        <asp:MenuItem NavigateUrl="~/Admin/SetVip.aspx" Text="VIP 1-20"/>'
$patchedNavigation = Ensure-AsciiLineAfterAnchor $master '~/Admin/SetVip.aspx' $anchor $vipLine

$pageHash = (Get-FileHash -LiteralPath $pageTarget -Algorithm SHA256).Hash
$dllHash = (Get-FileHash -LiteralPath $dllTarget -Algorithm SHA256).Hash
$masterShadow = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($master))
if ([regex]::Matches($masterShadow,[regex]::Escape('~/Admin/SetVip.aspx')).Count -ne 1) { throw 'AdminGunny VIP navigation is not exactly-once after deploy.' }
Write-Host ("DDTANK30_ADMIN_VIP20_DEPLOY=PASS pageSha=$pageHash dllSha=$dllHash navPatched=$patchedNavigation backup=$backupRoot")
