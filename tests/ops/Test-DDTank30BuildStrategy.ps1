$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$build=Join-Path $repo 'deploy\Build-DDTank30.ps1'
if(-not(Test-Path $build)){throw 'Missing Build-DDTank30.ps1'}
$raw=Get-Content $build -Raw
if($raw -match '/t:Rebuild'){throw 'Build script must not use aggregate /t:Rebuild with overlapping project references.'}
if($raw -notmatch '/t:Clean'){throw 'Build script must have an explicit clean phase.'}
if($raw -notmatch '/t:Build'){throw 'Build script must have a separate build phase.'}
if($raw -notmatch '\[string\]\$RuntimeRoot'){throw 'Build script must allow an isolated RuntimeRoot for non-disruptive packaging.'}
if($raw -match '(?m)^\$runtimeRoot\s*=\s*''C:\\Gunny-DDTank30\\runtime'''){throw 'Build script must not overwrite the RuntimeRoot parameter with a hardcoded live path.'}
if($raw -notmatch 'Clear-DDTank30StaleBuildOutputs'){throw 'Build script must purge stale tracked build outputs before MSBuild.'}
if($raw -notmatch 'obj\\Release'){throw 'Build script must purge stale obj/Release intermediates.'}
foreach($extension in @('.dll','.pdb','.exe')){if($raw -notmatch [regex]::Escape($extension)){throw "Build artifact purge must cover $extension outputs."}}
$coreProjects=@('Game.Base\Game.Base.csproj','SqlDataProvider\SqlDataProvider.csproj','Bussiness\Bussiness.csproj','Game.Logic\Game.Logic.csproj','Road.Flash\Road.Flash.csproj','Game.Server\Game.Server.csproj')
foreach($project in $coreProjects){if($raw -notmatch [regex]::Escape($project)){throw "Build script must explicitly clean/build source dependency: $project"}}
$packageRaw=Get-Content (Join-Path $repo 'tests\ops\Test-DDTank30Package.ps1') -Raw
foreach($language in @('center\Languages\Language-vn.txt','center\Languages\Language-zh_cn.txt')){if($packageRaw -notmatch [regex]::Escape($language)){throw "Package gate must require restart-critical center language: $language"}}
Write-Host 'PASS: DDTank30 build separates clean and build phases.'
