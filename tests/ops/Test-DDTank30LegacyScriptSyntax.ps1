$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$root = Join-Path $repo 'GameServerScript'
$pattern = '[A-Za-z_][A-Za-z0-9_]*\s*:\s*(true|false|null|-?[0-9]+)'

$matches = @(Get-ChildItem -LiteralPath $root -Recurse -Filter *.cs -File |
    Select-String -Pattern $pattern)

if ($matches.Count -gt 0) {
    $details = $matches | ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" }
    throw ('Legacy runtime CodeDom does not support named arguments found in runtime scripts:' + [Environment]::NewLine + ($details -join [Environment]::NewLine))
}

Write-Host 'DDTANK30_LEGACY_SCRIPT_SYNTAX=PASS'
