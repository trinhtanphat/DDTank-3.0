$ErrorActionPreference = 'Stop'
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$weekly = Join-Path $repo 'runtime-assets\v30\Resource\image\weekly'
$info = Join-Path $weekly 'weeklyInfo.xml'
if (-not (Test-Path $info)) { throw "Missing weeklyInfo.xml: $info" }

[xml]$xml = Get-Content $info -Raw
if ($xml.Result.value -ne 'true') { throw 'weeklyInfo.xml result is not enabled' }
$items = @($xml.Result.item)
if ($items.Count -lt 5) { throw "Expected at least 5 weekly items, found $($items.Count)" }

$missing = @()
foreach ($item in $items) {
    foreach ($attribute in @('path','thumbnailPath')) {
        $value = [string]$item.$attribute
        if (-not $value -or $value -eq 'null') { continue }
        if (-not (Test-Path (Join-Path $weekly $value))) {
            $missing += "$attribute=$value"
        }
    }
}
if ($missing.Count) { throw ('Missing weekly asset references: ' + ($missing -join ', ')) }
if ((Get-Content $info -Raw) -match 'thumbnailPath="null"') { throw 'weeklyInfo.xml still contains null thumbnails' }
Write-Host "DDTANK30_WEEKLY_ASSETS=PASS items=$($items.Count) files=$((Get-ChildItem $weekly -File).Count)"
