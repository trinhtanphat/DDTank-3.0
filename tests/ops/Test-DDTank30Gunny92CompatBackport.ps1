$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$manifest=Import-Csv (Join-Path $PSScriptRoot 'DDTank30Gunny92CompatBackport.manifest.tsv') -Delimiter "`t"
if(@($manifest).Count -ne 4){throw "Expected 4 Gunny92 compat rows, got $(@($manifest).Count)"}
$expectedSource='trinhtanphat/Gunny92-001-code-backup@e53c3950f40a938fb0013be33230325e99397860'
if(@($manifest|Where-Object source -ne $expectedSource).Count){throw 'Gunny92 source provenance mismatch.'}
$projectRaw=Get-Content (Join-Path $repo 'GameServerScript\GameServerScript.csproj') -Raw
foreach($row in $manifest){
  $p=Join-Path (Join-Path $repo 'GameServerScript') $row.path
  if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing Gunny92 compat source: $($row.path)"}
  $hash=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
  if($hash-ne$row.sha256){throw "Gunny92 compat hash mismatch: $($row.path)"}
  if((Get-Item -LiteralPath $p).Length-ne[int64]$row.bytes){throw "Gunny92 compat size mismatch: $($row.path)"}
  if($projectRaw -notmatch [regex]::Escape('<Compile Include="'+$row.path+'" />')){throw "Gunny92 compat source missing from csproj: $($row.path)"}
  $code=Get-Content -LiteralPath $p -Raw
  $short=($row.class -split '\.')[-1]
  if($code -notmatch ('(?m)^\s*public\s+(?:sealed\s+|abstract\s+)?class\s+'+[regex]::Escape($short)+'\b')){throw "Class declaration mismatch: $($row.class)"}
}
Write-Output "DDTANK30_GUNNY92_COMPAT_BACKPORT=PASS rows=$(@($manifest).Count)"
