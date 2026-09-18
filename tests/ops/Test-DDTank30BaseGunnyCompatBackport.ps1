$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$manifest = @(Import-Csv (Join-Path $PSScriptRoot 'DDTank30BaseGunnyCompatBackport.manifest.tsv') -Delimiter "`t")
if ($manifest.Count -ne 1) { throw "Expected 1 BaseGunny compat row, got $($manifest.Count)." }
$expectedSource = 'trinhtanphat/BaseGunnyII@94df4bc8add1d605a098ae44e291015c453100fe'
if ($manifest[0].source -ne $expectedSource) { throw 'BaseGunny source provenance mismatch.' }
$projectRaw = Get-Content (Join-Path $repo 'GameServerScript\GameServerScript.csproj') -Raw
$utf8 = New-Object Text.UTF8Encoding($false)
foreach ($row in $manifest) {
  $path = Join-Path (Join-Path $repo 'GameServerScript') $row.path
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing BaseGunny compat source: $($row.path)" }
  $code = [IO.File]::ReadAllText($path); $canonical = ($code -replace "`r`n","`n" -replace "`r","`n")
  $bytes = $utf8.GetBytes($canonical); $sha = [Security.Cryptography.SHA256]::Create()
  try { $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','') } finally { $sha.Dispose() }
  if ($hash -ne $row.sha256) { throw "BaseGunny canonical hash mismatch: $($row.path)" }
  if ($bytes.Length -ne [int64]$row.bytes) { throw "BaseGunny canonical size mismatch: $($row.path)" }
  if ($projectRaw -notmatch [regex]::Escape('<Compile Include="'+$row.path+'" />')) { throw "BaseGunny source missing from csproj: $($row.path)" }
  if ($code -notmatch '(?m)^\s*public\s+(?:sealed\s+|abstract\s+)?class\s+FiveNormalFirstNpc\b') { throw 'FiveNormalFirstNpc declaration mismatch.' }
}
Write-Output "DDTANK30_BASEGUNNY_COMPAT_BACKPORT=PASS rows=$($manifest.Count) canonical=utf8-lf"
