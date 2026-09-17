$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$build=Join-Path $repo 'deploy\Build-DDTank30.ps1'
if(-not(Test-Path $build)){throw 'Missing Build-DDTank30.ps1'}
$raw=Get-Content $build -Raw
if($raw -match '/t:Rebuild'){throw 'Build script must not use aggregate /t:Rebuild with overlapping project references.'}
if($raw -notmatch '/t:Clean'){throw 'Build script must have an explicit clean phase.'}
if($raw -notmatch '/t:Build'){throw 'Build script must have a separate build phase.'}
$coreProjects=@('Game.Base\Game.Base.csproj','SqlDataProvider\SqlDataProvider.csproj','Bussiness\Bussiness.csproj','Game.Logic\Game.Logic.csproj','Road.Flash\Road.Flash.csproj','Game.Server\Game.Server.csproj')
foreach($project in $coreProjects){if($raw -notmatch [regex]::Escape($project)){throw "Build script must explicitly clean/build source dependency: $project"}}
Write-Host 'PASS: DDTank30 build separates clean and build phases.'