$ErrorActionPreference='Stop'
$p=Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'deploy\Initialize-DDTank30Databases.ps1'
$raw=Get-Content $p -Raw
foreach($token in @('Tank.bak','count.bak','716DC3137308E163F539E27CFA9D3BB34697EFBFE823C7FB18311BFEB58BFE36','BA1ED1E4D291D64E577D1385E9905F3C31B3B0A02D5E7FF5EC5148DEFB417026')){if($raw -notmatch [regex]::Escape($token)){throw "Initializer missing authoritative DDTank3 source token: $token"}}
if($raw -match "Clone-Database\s+\$c\s+'Db_Tank'"){throw 'Initializer still clones legacy Db_Tank.'}
if($raw -notmatch 'Edition' -or $raw -notmatch '21000'){throw 'Initializer must validate Edition 21000.'}
Write-Host 'PASS: DDTank30 database initializer is pinned to authoritative 3.0 backups.'