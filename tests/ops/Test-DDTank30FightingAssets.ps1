$ErrorActionPreference = 'Stop'
$map = 'C:\Gunny-DDTank30\runtime\fighting\map'
if (-not (Test-Path $map)) { throw 'DDTank30 Fighting runtime map directory is missing.' }
$count = @(Get-ChildItem $map -File -Recurse -ErrorAction Stop).Count
if ($count -lt 100) { throw "DDTank30 Fighting runtime map payload is incomplete: $count files." }
Write-Host "PASS: DDTank30 Fighting runtime has map payload ($count files)."
