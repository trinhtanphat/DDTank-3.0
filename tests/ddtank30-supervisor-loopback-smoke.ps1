$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$start=Get-Content (Join-Path $root 'deploy\Start-DDTank30Supervisor.ps1') -Raw
$stop=Get-Content (Join-Path $root 'deploy\Stop-DDTank30Supervisor.ps1') -Raw
foreach($raw in @($start,$stop)){
  if($raw -notmatch [regex]::Escape("InternalHost='127.0.0.1'") -and $raw -notmatch [regex]::Escape("InternalHost = '127.0.0.1'")){throw 'Supervisor scripts must default InternalHost to 127.0.0.1.'}
  if($raw -notmatch 'LocalAddress\s*-eq\s*\$InternalHost'){throw 'Supervisor scripts must filter listeners by InternalHost.'}
}
if($start -notmatch 'function Listener\('){throw 'Start supervisor listener helper missing.'}
if($start -match 'Where-Object\s*\{\s*\$_.LocalPort\s*-eq\s*\$port\s*\}'){throw 'Start supervisor must not treat public edge listeners as internal port conflicts.'}
if($stop -match 'Where-Object\s*\{\s*\$_.LocalPort\s*-in\s*9300,9302,9308\s*\}'){throw 'Stop supervisor must not fail on public edge listeners.'}
Write-Host 'DDTANK30_SUPERVISOR_LOOPBACK=PASS'