$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script=Join-Path $repo 'deploy\Start-DDTank30Supervisor.ps1'
$installer=Join-Path $repo 'deploy\Install-DDTank30Supervisor.ps1'
if(-not(Test-Path $script)){throw 'Missing DDTank30 supervisor script'}
if(-not(Test-Path $installer)){throw 'Missing DDTank30 supervisor installer'}
$stopper=Join-Path $repo 'deploy\Stop-DDTank30Supervisor.ps1'
if(-not(Test-Path $stopper)){throw 'Missing DDTank30 supervisor stop script'}
$stopRaw=Get-Content $stopper -Raw
foreach($needle in @('C:\Gunny-DDTank30\runtime','Stop-ScheduledTask','ExecutablePath')){if($stopRaw -notlike ('*'+$needle+'*')){throw "Stop script missing contract: $needle"}}
foreach($forbidden in @('C:\Gunny\GunnyFileExe','9200','9202','9208')){if($stopRaw -like ('*'+$forbidden+'*')){throw "Stop script references legacy stack: $forbidden"}}
$raw=Get-Content $script -Raw
$installRaw=Get-Content $installer -Raw
foreach($needle in @('C:\Gunny-DDTank30\runtime','center','Center.Service.exe','fighting','Fighting.Service.exe','game','Road.Service.exe','RedirectStandardInput','9302','9308','9300')){if($raw -notlike ('*'+$needle+'*')){throw "Supervisor missing contract: $needle"}}
foreach($forbidden in @('C:\Gunny\GunnyFileExe','9200','9202','9208')){if($raw -like ('*'+$forbidden+'*')){throw "Supervisor references legacy stack: $forbidden"}}
if($raw -match 'Select-Object\s+-Reverse'){throw 'Supervisor cleanup uses invalid Select-Object -Reverse'}
if($installRaw -notlike '*IS_ROLEMEMBER*'){throw 'Installer SQL role grant is not idempotent'}
if($installRaw -notlike '*DDTank30-Stack*'){throw 'Installer task name missing'}
if($installRaw -notlike '*Start-DDTank30Supervisor.ps1*'){throw 'Installer does not invoke supervisor'}
if($installRaw -notlike '*-RestartCount 5*'){throw 'Supervisor recovery must use a bounded five-retry policy'}
if($installRaw -like '*-RestartCount 99*'){throw 'Supervisor recovery still uses the old 99-retry loop'}
if($raw -notlike '*supervisor failed:*'){throw 'Supervisor does not persist failure reason before recovery'}
Write-Host 'PASS: DDTank30 supervisor is isolated and preserves console stdin.'
