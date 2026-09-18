$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$manifest=Import-Csv (Join-Path $PSScriptRoot 'DDTank30SkelletonxCompatBackport.manifest.tsv') -Delimiter "`t"
if(@($manifest).Count -ne 4){throw "Expected 4 SkelletonX compat rows, got $(@($manifest).Count)"}
$expectedSource='SkelletonX/DDTank4.1@09f8cdb2891ef0b49f44c4d6f68035a728623c00'
if(@($manifest|Where-Object source -ne $expectedSource).Count){throw 'SkelletonX source provenance mismatch.'}
$projectRaw=Get-Content (Join-Path $repo 'GameServerScript\GameServerScript.csproj') -Raw
$utf8=New-Object Text.UTF8Encoding($false)
foreach($row in $manifest){
  $p=Join-Path (Join-Path $repo 'GameServerScript') $row.path
  if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing SkelletonX compat source: $($row.path)"}
  $code=[IO.File]::ReadAllText($p); $canonical=($code -replace "`r`n","`n" -replace "`r","`n")
  $bytes=$utf8.GetBytes($canonical); $sha=[Security.Cryptography.SHA256]::Create()
  try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')}finally{$sha.Dispose()}
  if($hash-ne$row.sha256){throw "SkelletonX compat canonical hash mismatch: $($row.path)"}
  if($bytes.Length-ne[int64]$row.bytes){throw "SkelletonX compat canonical size mismatch: $($row.path)"}
  if($projectRaw -notmatch [regex]::Escape('<Compile Include="'+$row.path+'" />')){throw "SkelletonX source missing from csproj: $($row.path)"}
  $short=($row.class -split '\.')[-1]; if($code -notmatch ('(?m)^\s*public\s+(?:sealed\s+|abstract\s+)?class\s+'+[regex]::Escape($short)+'\b')){throw "Class declaration mismatch: $($row.class)"}
}
Write-Output "DDTANK30_SKELLETONX_COMPAT_BACKPORT=PASS rows=$(@($manifest).Count) canonical=utf8-lf"
