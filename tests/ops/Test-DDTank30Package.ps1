param(
    [string]$RuntimeRoot = 'C:\Gunny-DDTank30\runtime'
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runtime = $RuntimeRoot
$external = 'C:\Gunny-DDTank30\external-sources\dk-khoado-Gunny-3.0'
$required = @(
    'center\Center.Service.exe','center\Center.Server.dll','center\Center.Service.exe.config',
    'center\Languages\Language-vn.txt','center\Languages\Language-zh_cn.txt',
    'fighting\Fighting.Service.exe','fighting\Fighting.Server.dll','fighting\Fighting.Service.exe.config',
    'game\Road.Service.exe','game\Road.Service.exe.config','game\Game.Server.dll','game\battle.xml',
    'core-sha256.txt','provenance.txt','package-files.txt'
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $runtime $_)) })
if ($missing.Count) { throw "Missing runtime artifact(s): $($missing -join ', ')" }
$packageFiles = @(Get-Content -LiteralPath (Join-Path $runtime 'package-files.txt'))
foreach ($forbidden in @('game\GameServerScripts.dll','game\GameServerScripts.pdb')) {
    if ($packageFiles -contains $forbidden) { throw "Stale runtime-compiled artifact was in package manifest: $forbidden" }
}
$coreManifest = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $runtime 'core-sha256.txt')) {
    if ($line -notmatch '^([A-Fa-f0-9]{64})\s{2}(.+)$') { throw "Malformed core hash manifest line: $line" }
    $coreManifest[$matches[2]] = $matches[1].ToUpperInvariant()
}
$expectedCore = @(
    'center\Center.Service.exe','center\Center.Server.dll',
    'fighting\Fighting.Service.exe','fighting\Fighting.Server.dll',
    'game\Road.Service.exe','game\Game.Server.dll'
)
if ($coreManifest.Count -ne $expectedCore.Count) { throw "Core hash manifest count mismatch: $($coreManifest.Count)/$($expectedCore.Count)" }
foreach ($relative in $expectedCore) {
    if (-not $coreManifest.ContainsKey($relative)) { throw "Core hash manifest missing: $relative" }
    $runtimeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $runtime $relative)).Hash.ToUpperInvariant()
    if ($runtimeHash -ne $coreManifest[$relative]) { throw "Runtime core hash mismatch: $relative" }
}
$firstParty = @('Bussiness.dll','Game.Base.dll','SqlDataProvider.dll')
foreach ($name in $firstParty) {
    foreach ($service in @('center','fighting','game')) {
        $runtimeFile = Join-Path $runtime "$service\$name"
        if (-not (Test-Path $runtimeFile)) { throw "Missing first-party dependency: $service/$name" }
    }
}
foreach ($name in @('Game.Logic.dll')) {
    foreach ($service in @('fighting','game')) {
        if (-not (Test-Path (Join-Path $runtime "$service\$name"))) { throw "Missing first-party dependency: $service/$name" }
    }
}
$clr2Guard = Join-Path $repo 'deploy\Test-DDTank30Clr2Runtime.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $clr2Guard -RuntimeRoot $runtime
if ($LASTEXITCODE -ne 0) { throw "CLR2 runtime guard failed with exit $LASTEXITCODE" }
$scriptCount = @(Get-ChildItem -LiteralPath (Join-Path $runtime 'game\scripts') -Filter *.cs -File -Recurse -ErrorAction SilentlyContinue).Count
if ($scriptCount -ne 179) { throw "Expected 179 fresh GameServerScript sources, found $scriptCount." }
$externalMap = Join-Path $external 'Server\Fight\map'
$externalBomb = Join-Path $external 'Server\Fight\bomb'
$runtimeMap = Join-Path $runtime 'fighting\map'
$runtimeBomb = Join-Path $runtime 'fighting\bomb'
foreach ($check in @(@($externalMap,$runtimeMap,251,'map'),@($externalBomb,$runtimeBomb,494,'bomb'))) {
    $srcFiles = @(Get-ChildItem -LiteralPath $check[0] -File -Recurse)
    $dstFiles = @(Get-ChildItem -LiteralPath $check[1] -File -Recurse -ErrorAction SilentlyContinue)
    if ($srcFiles.Count -ne $check[2]) { throw "External $($check[3]) source count drift: $($srcFiles.Count)" }
    if ($dstFiles.Count -ne $srcFiles.Count) { throw "Runtime $($check[3]) count mismatch: $($dstFiles.Count)/$($srcFiles.Count)" }
    foreach ($src in $srcFiles) {
        $rel = $src.FullName.Substring($check[0].Length + 1)
        $dst = Join-Path $check[1] $rel
        if (-not (Test-Path $dst)) { throw "Missing runtime $($check[3]) asset: $rel" }
        if ((Get-FileHash $src.FullName -Algorithm SHA256).Hash -ne (Get-FileHash $dst -Algorithm SHA256).Hash) {
            throw "Runtime $($check[3]) asset hash mismatch: $rel"
        }
    }
}
$head = (git -C $external rev-parse HEAD).Trim()
$provenance = Get-Content -LiteralPath (Join-Path $runtime 'provenance.txt') -Raw
foreach ($need in @('center=fresh-source-build','fighting=fresh-source-build','game=fresh-source-build','game-scripts=fresh-source-tree;count=179;dk-additive=46;dk-source=dk-khoado/Gunny-3.0@16e24b119f96b93b34ddb148f9a035f71a234e67;ddt34-additive=12;ddt34-source=barrydevp/ddt3.4server@73e189aef774b1f2eead70979c97b53619db07aa;barry34-brainhook-additive=5;barry34-brainhook-source=barrydevp/ddt3.4server@73e189aef774b1f2eead70979c97b53619db07aa;gunny92-additive=4;gunny92-source=trinhtanphat/Gunny92-001-code-backup@e53c3950f40a938fb0013be33230325e99397860;yuti-additive=11;yuti-source=yutikeyux/ddt-34-csharp@b90215e199ae079c05eb290ed1cbf2a2fb4bdf5e;skelletonx-additive=4;skelletonx-source=SkelletonX/DDTank4.1@09f8cdb2891ef0b49f44c4d6f68035a728623c00;basegunny-additive=1;basegunny-source=trinhtanphat/BaseGunnyII@94df4bc8add1d605a098ae44e291015c453100fe',"combat-assets=dk-khoado/Gunny-3.0@$head")) {
    if ($provenance -notmatch [regex]::Escape($need)) { throw "Missing provenance: $need" }
}
if ($provenance -match 'game=(prebuilt|server1)') { throw 'Prebuilt game core provenance is forbidden.' }
function Assert-AppSetting([string]$configPath,[string]$key,[string]$expected) {
    [xml]$xml = Get-Content -LiteralPath $configPath
    $node = $xml.configuration.appSettings.add | Where-Object { $_.key -eq $key }
    if (-not $node -or [string]$node.value -ne $expected) { throw "Runtime config mismatch: $key" }
}
Assert-AppSetting (Join-Path $runtime 'center\Center.Service.exe.config') 'Port' '9302'
Assert-AppSetting (Join-Path $runtime 'fighting\Fighting.Service.exe.config') 'Port' '9308'
Assert-AppSetting (Join-Path $runtime 'game\Road.Service.exe.config') 'Port' '9300'
Assert-AppSetting (Join-Path $runtime 'game\Road.Service.exe.config') 'LoginServerPort' '9302'
Assert-AppSetting (Join-Path $runtime 'game\Road.Service.exe.config') 'FightServerPort' '9308'
Write-Host 'PASS: DDTank30 package is fresh-source-built and external combat assets match the DDTank3 DB source.'
