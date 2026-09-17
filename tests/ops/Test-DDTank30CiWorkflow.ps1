$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workflow=Join-Path $repo '.github\workflows\ddtank30-contract.yml'
if(-not(Test-Path $workflow)){throw 'Missing DDTank30 contract CI workflow.'}
$raw=Get-Content $workflow -Raw
foreach($token in @('windows-latest','Test-DDTank30BuildStrategy.ps1','Test-DDTank30DatabaseSource.ps1','Test-DDTank30DbAuth.ps1','Test-DDTank30GameServerProject.ps1','Test-DDTank30Isolation.ps1','Test-DDTank30WcfIsolation.ps1','Test-DDTank30WebInstaller.ps1')){if($raw -notmatch [regex]::Escape($token)){throw "CI workflow missing token: $token"}}
foreach($liveOnly in @('Test-DDTank30Databases.ps1','Test-DDTank30Edition.ps1','Test-DDTank30FightingAssets.ps1','Test-DDTank30Package.ps1','Test-DDTank30PublicEndpoint.ps1','Test-DDTank30RuntimeConfig.ps1','Test-DDTank30Supervisor.ps1','Test-DDTank30Web.ps1')){if($raw -match [regex]::Escape($liveOnly)){throw "CI workflow must not run VPS-only gate: $liveOnly"}}
Write-Host 'PASS: DDTank30 GitHub CI runs only source-contract gates on Windows.'
