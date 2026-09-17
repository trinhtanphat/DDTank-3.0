param(
    [string]$RuntimeRoot = 'C:\Gunny-DDTank30\runtime'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$external = 'C:\Gunny-DDTank30\external-sources\dk-khoado-Gunny-3.0'
$msbuild = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe'
if (-not (Test-Path $msbuild)) { throw 'MSBuild.exe was not found.' }
if (-not (Test-Path (Join-Path $external '.git'))) { throw 'External DDTank3 source clone is missing.' }

$projects = @(
    'Game.Base\Game.Base.csproj',
    'SqlDataProvider\SqlDataProvider.csproj',
    'Bussiness\Bussiness.csproj',
    'Game.Logic\Game.Logic.csproj',
    'Center.Server\Center.Server.csproj',
    'Fighting.Server\Fighting.Server.csproj',
    'Road.Flash\Road.Flash.csproj',
    'Game.Server\Game.Server.csproj',
    'Center.Service\Center.Service.csproj',
    'Fighting.Service\Fighting.Service.csproj',
    'GameServerScript\GameServerScript.csproj',
    'Game.Service\Game.Service.csproj'
)

function Clear-DDTank30StaleBuildOutputs([string]$ProjectPath) {
    $projectDir = Split-Path (Join-Path $repoRoot $ProjectPath) -Parent
    $objRelease = Join-Path $projectDir 'obj\Release'
    if (Test-Path -LiteralPath $objRelease) {
        Remove-Item -LiteralPath $objRelease -Recurse -Force
    }

    $binRelease = Join-Path $projectDir 'bin\Release'
    if (Test-Path -LiteralPath $binRelease) {
        $binaryExtensions = @('.dll','.pdb','.exe','.application','.manifest','.nlp')
        Get-ChildItem -LiteralPath $binRelease -File -Recurse | Where-Object {
            $binaryExtensions -contains $_.Extension.ToLowerInvariant()
        } | Remove-Item -Force
    }
}

foreach ($project in $projects) {
    Write-Host "Purging stale build artifacts for $project..."
    Clear-DDTank30StaleBuildOutputs $project
}
foreach ($project in $projects) {
    Write-Host "Cleaning $project..."
    & $msbuild (Join-Path $repoRoot $project) /t:Clean /p:Configuration=Release /p:Platform=AnyCPU /nologo /verbosity:minimal
    if ($LASTEXITCODE -ne 0) { throw "Clean failed: $project exit=$LASTEXITCODE" }
}
foreach ($project in $projects) {
    Write-Host "Building $project..."
    & $msbuild (Join-Path $repoRoot $project) /t:Build /p:Configuration=Release /p:Platform=AnyCPU /nologo /verbosity:minimal
    if ($LASTEXITCODE -ne 0) { throw "Build failed: $project exit=$LASTEXITCODE" }
}

function Reset-Dir([string]$path) {
    if (Test-Path $path) { Remove-Item -LiteralPath $path -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}
function Copy-Required([string]$source,[string]$destination) {
    if (-not (Test-Path -LiteralPath $source)) { throw "Required package input missing: $source" }
    New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
}
function Copy-ReleaseSet([string]$projectDir,[string]$target,[string[]]$names) {
    foreach ($name in $names) {
        Copy-Required (Join-Path $repoRoot "$projectDir\bin\Release\$name") (Join-Path $target $name)
    }
}

$center = Join-Path $runtimeRoot 'center'
$fighting = Join-Path $runtimeRoot 'fighting'
$game = Join-Path $runtimeRoot 'game'
Reset-Dir $center; Reset-Dir $fighting; Reset-Dir $game

Copy-ReleaseSet 'Center.Service' $center @('Center.Service.exe','Center.Server.dll','Bussiness.dll','Game.Base.dll','SqlDataProvider.dll')
Copy-ReleaseSet 'Fighting.Service' $fighting @('Fighting.Service.exe','Fighting.Server.dll','Bussiness.dll','Game.Base.dll','Game.Logic.dll','SqlDataProvider.dll')
Copy-ReleaseSet 'Game.Service' $game @('Road.Service.exe','Bussiness.dll','Game.Base.dll','Game.Logic.dll','Game.Server.dll','SqlDataProvider.dll')

$lib = Join-Path $repoRoot 'Lib'
foreach ($target in @($center,$fighting,$game)) {
    foreach ($name in @('log4net.dll','zlib.net.dll')) { Copy-Required (Join-Path $lib $name) (Join-Path $target $name) }
}
Copy-Required (Join-Path $lib 'Newtonsoft.Json.dll') (Join-Path $center 'Newtonsoft.Json.dll')
foreach ($name in @('Newtonsoft.Json.dll','lua51.dll','LuaInterface.dll')) { Copy-Required (Join-Path $lib $name) (Join-Path $game $name) }

Copy-Required (Join-Path $repoRoot 'Center.Service\App.config') (Join-Path $center 'Center.Service.exe.config')
Copy-Required (Join-Path $repoRoot 'Fighting.Service\App.config') (Join-Path $fighting 'Fighting.Service.exe.config')
Copy-Required (Join-Path $repoRoot 'Game.Service\App.config') (Join-Path $game 'Road.Service.exe.config')
Copy-Required (Join-Path $repoRoot 'Game.Service\battle.xml') (Join-Path $game 'battle.xml')
Copy-Required (Join-Path $repoRoot 'Center.Service\bin\Release\logconfig.xml') (Join-Path $center 'logconfig.xml')
Copy-Required (Join-Path $repoRoot 'Fighting.Service\logconfig.xml') (Join-Path $fighting 'logconfig.xml')
Copy-Required (Join-Path $repoRoot 'Game.Service\logconfig.xml') (Join-Path $game 'logconfig.xml')

$languageSets = @(
    @((Join-Path $external 'Server\Center\Languages'),(Join-Path $center 'Languages')),
    @((Join-Path $external 'Server\Fight\Languages'),(Join-Path $fighting 'Languages')),
    @((Join-Path $external 'Server\Road\Languages'),(Join-Path $game 'Languages'))
)
foreach ($pair in $languageSets) {
    if (-not (Test-Path $pair[0])) { throw "External language source missing: $($pair[0])" }
    Copy-Item -LiteralPath $pair[0] -Destination $pair[1] -Recurse -Force
}

$mapSource = Join-Path $external 'Server\Fight\map'
$bombSource = Join-Path $external 'Server\Fight\bomb'
$mapCount = @(Get-ChildItem $mapSource -File -Recurse -ErrorAction Stop).Count
$bombCount = @(Get-ChildItem $bombSource -File -Recurse -ErrorAction Stop).Count
if ($mapCount -ne 251) { throw "External DDTank3 map count drift: $mapCount" }
if ($bombCount -ne 494) { throw "External DDTank3 bomb count drift: $bombCount" }
foreach ($target in @($fighting,$game)) {
    Copy-Item -LiteralPath $mapSource -Destination (Join-Path $target 'map') -Recurse -Force
    Copy-Item -LiteralPath $bombSource -Destination (Join-Path $target 'bomb') -Recurse -Force
}

$scriptSource = Join-Path $repoRoot 'GameServerScript'
$scriptTarget = Join-Path $game 'scripts'
New-Item -ItemType Directory -Force -Path $scriptTarget | Out-Null
$scripts = @(Get-ChildItem $scriptSource -Filter *.cs -File -Recurse | Where-Object { $_.FullName -notmatch '\\(bin|obj)\\' })
foreach ($file in $scripts) {
    $relative = $file.FullName.Substring($scriptSource.Length).TrimStart('\')
    $dest = Join-Path $scriptTarget $relative
    New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
}
if ($scripts.Count -ne 154) { throw "Expected 154 GameServerScript source files, found $($scripts.Count)." }

foreach ($forbidden in @('GameServerScripts.dll','GameServerScripts.pdb')) {
    $path = Join-Path $game $forbidden
    if (Test-Path $path) { throw "Stale runtime-compiled artifact was packaged: $path" }
}

$coreFiles = @(
    'center\Center.Service.exe','center\Center.Server.dll',
    'fighting\Fighting.Service.exe','fighting\Fighting.Server.dll',
    'game\Road.Service.exe','game\Game.Server.dll'
)
$manifest = foreach ($relative in $coreFiles) {
    $hash = Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $runtimeRoot $relative)
    "$($hash.Hash)  $relative"
}
[IO.File]::WriteAllLines((Join-Path $runtimeRoot 'core-sha256.txt'),$manifest,(New-Object Text.UTF8Encoding($false)))
$externalHead = (git -C $external rev-parse HEAD).Trim()
@(
    'center=fresh-source-build',
    'fighting=fresh-source-build',
    'game=fresh-source-build',
    "game-scripts=fresh-source-tree;count=$($scripts.Count);dk-additive=46;dk-source=dk-khoado/Gunny-3.0@16e24b119f96b93b34ddb148f9a035f71a234e67;ddt34-additive=12;ddt34-source=barrydevp/ddt3.4server@73e189aef774b1f2eead70979c97b53619db07aa",
    'third-party-libraries=repo-Lib',
    "combat-assets=dk-khoado/Gunny-3.0@$externalHead",
    "combat-map-files=$mapCount",
    "combat-bomb-files=$bombCount",
    'languages=dk-khoado/Gunny-3.0 server-specific',
    'config=source-isolated ports 9300/9302/9308'
) | Set-Content -LiteralPath (Join-Path $runtimeRoot 'provenance.txt') -Encoding UTF8
$packageFiles = @(Get-ChildItem -LiteralPath $runtimeRoot -File -Recurse | Where-Object { $_.Name -ne 'package-files.txt' } | ForEach-Object { $_.FullName.Substring($runtimeRoot.Length + 1) } | Sort-Object)
[IO.File]::WriteAllLines((Join-Path $runtimeRoot 'package-files.txt'),$packageFiles,(New-Object Text.UTF8Encoding($false)))
Write-Host "PACKAGED_DDTANK30_SOURCE_BUILD=PASS scripts=$($scripts.Count) maps=$mapCount bombs=$bombCount external=$externalHead"
