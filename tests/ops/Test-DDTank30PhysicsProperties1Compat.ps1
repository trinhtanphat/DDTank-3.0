$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$physicsPath = Join-Path $repo 'Game.Logic\Phy\Object\Physics.cs'
$provPath = Join-Path $repo 'Game.Logic\PHYSICS-PROPERTIES1-COMPAT.md'
$commit = '73e189aef774b1f2eead70979c97b53619db07aa'

if (-not (Test-Path -LiteralPath $physicsPath)) { throw 'Physics.cs missing.' }
$raw = Get-Content $physicsPath -Raw
if ($raw -notmatch 'private\s+int\s+properties1\s*;') { throw 'Physics.Properties1 backing field must be an int.' }
$propertyPattern = 'public\s+int\s+Properties1\s*\{\s*get\s*\{\s*return\s+properties1\s*;\s*\}\s*set\s*\{\s*properties1\s*=\s*value\s*;\s*\}\s*\}'
if (-not [regex]::IsMatch($raw,$propertyPattern,[Text.RegularExpressions.RegexOptions]::Singleline)) { throw 'Physics.Properties1 must be a direct int getter/setter over the local state slot.' }
$propertyText = [regex]::Match($raw,$propertyPattern,[Text.RegularExpressions.RegexOptions]::Singleline).Value
if ($propertyText -match 'NpcInfo|SqlDataProvider|Send|Packet|Game') { throw 'Physics.Properties1 must remain a pure process-local state slot.' }

if (-not (Test-Path -LiteralPath $provPath)) { throw 'Properties1 compatibility provenance is missing.' }
$prov = Get-Content $provPath -Raw
if ($prov -notmatch [regex]::Escape($commit)) { throw 'Properties1 provenance commit is missing.' }
if ($prov -notmatch 'process-local integer state slot' -or $prov -notmatch 'defaults to `0`') {
    throw 'Properties1 provenance must document local integer/default-zero semantics.'
}
Write-Host 'DDTANK30_PHYSICS_PROPERTIES1_COMPAT=PASS type=int default=0 scope=process-local'
