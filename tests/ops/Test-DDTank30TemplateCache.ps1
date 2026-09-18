$ErrorActionPreference='Stop'

$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$p=Join-Path $repo 'deploy\Build-DDTank30TemplateCache.ps1'
if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'Missing Build-DDTank30TemplateCache.ps1'}
$raw=Get-Content -LiteralPath $p -Raw

foreach($token in @(
  '[string]$RequestRoot',
  '[string]$ExpectedDatabase = ''Db_Tank_V30''',
  '[int]$ExpectedMinimumCount = 3000',
  '[int]$ExpectedMinimumWeaponCount = 120',
  'Web.config',
  'conString',
  'SqlConnectionStringBuilder',
  'dbo.SP_Items_All',
  'StoredProcedure',
  'HashSet[int]',
  'Duplicate TemplateID',
  'CategoryID',
  'TemplateID',
  'Pic',
  'CanRecycle',
  'ReclaimType',
  'ReclaimValue',
  'zlib.net.dll',
  'zlib.ZOutputStream',
  '$zstream.Finish()',
  'Compressed TemplateAlllist output does not have a zlib header',
  '[Guid]::NewGuid()',
  'Move-Item -LiteralPath $tempPath -Destination $OutputPath -Force',
  'DDTANK30_TEMPLATE_CACHE=PASS'
)){
  if($raw -notmatch [regex]::Escape($token)){throw "Template cache builder missing token: $token"}
}

foreach($forbidden in @(
  'Db_Tank;',
  'User ID=sa',
  'Password=123456',
  '103.9.156.181'
)){
  if($raw -match [regex]::Escape($forbidden)){throw "Template cache builder contains forbidden environment coupling: $forbidden"}
}

Write-Host 'PASS: DDTank30 item template cache is rebuilt from Request DB with weapon-count, unique-ID and zlib guards.'
