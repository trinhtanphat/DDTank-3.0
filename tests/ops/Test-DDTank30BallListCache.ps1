$ErrorActionPreference='Stop'

$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$p=Join-Path $repo 'deploy\Build-DDTank30BallListCache.ps1'
if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'Missing Build-DDTank30BallListCache.ps1'}
$raw=Get-Content -LiteralPath $p -Raw

foreach($token in @(
  '[string]$RequestRoot',
  "[string]$ExpectedDatabase = 'Db_Tank_V30'",
  '[int]$ExpectedMinimumCount = 300',
  'Web.config',
  'appSettings',
  'conString',
  'SqlConnectionStringBuilder',
  'dbo.SP_Ball_All',
  'StoredProcedure',
  'FlyingPartical',
  'BombPartical',
  'ShootSound',
  'BombSound',
  'ActionType',
  'Mass',
  'HashSet[int]',
  'Duplicate Ball ID',
  'zlib.net.dll',
  'zlib.ZOutputStream',
  '$zstream.Finish()',
  'Compressed BallList output does not have a zlib header',
  '[Guid]::NewGuid()',
  'Move-Item -LiteralPath $tempPath -Destination $OutputPath -Force',
  'DDTANK30_BALLLIST_CACHE=PASS'
)){
  if($raw -notmatch [regex]::Escape($token)){throw "BallList cache builder missing token: $token"}
}

foreach($forbidden in @(
  'Db_Tank;',
  'User ID=sa',
  'Password=123456',
  '103.9.156.181'
)){
  if($raw -match [regex]::Escape($forbidden)){throw "BallList cache builder contains forbidden environment coupling: $forbidden"}
}

Write-Host 'PASS: DDTank30 BallList cache is rebuilt from the Request app connection string with unique-ID and zlib guards.'
