$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = New-Object System.Collections.Generic.List[string]

function Assert-Equal([string]$name, [string]$actual, [string]$expected) {
    if ($actual -ne $expected) { $failures.Add("$name expected '$expected' but was '$actual'") }
}

function Load-Config([string]$relativePath) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path $path)) { throw "Missing config: $relativePath" }
    [xml](Get-Content -LiteralPath $path -Raw)
}

function Get-AppSetting($xml, [string]$key) {
    $node = $xml.configuration.appSettings.add | Where-Object { $_.key -eq $key } | Select-Object -First 1
    if ($null -eq $node) { return $null }
    [string]$node.value
}

function Get-ConnectionCatalog($xml, [string]$name) {
    $node = $xml.configuration.connectionStrings.add | Where-Object { $_.name -eq $name } | Select-Object -First 1
    if ($null -eq $node) { return $null }
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder([string]$node.connectionString)
    [string]$builder.InitialCatalog
}
$center = Load-Config 'Center.Service\App.config'
Assert-Equal 'Center.Port' (Get-AppSetting $center 'Port') '9302'
Assert-Equal 'Center.Db_Tank' ((New-Object System.Data.SqlClient.SqlConnectionStringBuilder((Get-AppSetting $center 'conString'))).InitialCatalog) 'Db_Tank_V30'
Assert-Equal 'Center.Db_Count' ((New-Object System.Data.SqlClient.SqlConnectionStringBuilder((Get-AppSetting $center 'countDb'))).InitialCatalog) 'Db_Count_V30'

$fighting = Load-Config 'Fighting.Service\App.config'
Assert-Equal 'Fighting.Port' (Get-AppSetting $fighting 'Port') '9308'
Assert-Equal 'Fighting.Db_Tank' ((New-Object System.Data.SqlClient.SqlConnectionStringBuilder((Get-AppSetting $fighting 'conString'))).InitialCatalog) 'Db_Tank_V30'

$game = Load-Config 'Game.Service\App.config'
Assert-Equal 'Game.Port' (Get-AppSetting $game 'Port') '9300'
Assert-Equal 'Game.LoginServerPort' (Get-AppSetting $game 'LoginServerPort') '9302'
Assert-Equal 'Game.FightServerPort' (Get-AppSetting $game 'FightServerPort') '9308'
Assert-Equal 'Game.Db_Tank' ((New-Object System.Data.SqlClient.SqlConnectionStringBuilder((Get-AppSetting $game 'conString'))).InitialCatalog) 'Db_Tank_V30'
Assert-Equal 'Game.Db_Count' ((New-Object System.Data.SqlClient.SqlConnectionStringBuilder((Get-AppSetting $game 'countDb'))).InitialCatalog) 'Db_Count_V30'

[xml]$battle = Get-Content -LiteralPath (Join-Path $root 'Game.Service\battle.xml') -Raw
Assert-Equal 'Battle.FightingPort' ([string]$battle.list.server.port) '9308'

$admin = Load-Config 'GameAdmin\Web.config'
Assert-Equal 'Admin.Db_Tank' ((New-Object System.Data.SqlClient.SqlConnectionStringBuilder((Get-AppSetting $admin 'conString'))).InitialCatalog) 'Db_Tank_V30'
Assert-Equal 'Admin.Db_Count' ((New-Object System.Data.SqlClient.SqlConnectionStringBuilder((Get-AppSetting $admin 'countDb'))).InitialCatalog) 'Db_Count_V30'
foreach ($requestPath in @('Tank.Request\Web.config','Tank.Request\Tank.Request\Web.config')) {
    $request = Load-Config $requestPath
    Assert-Equal "$requestPath.Db_Tank" ((New-Object System.Data.SqlClient.SqlConnectionStringBuilder((Get-AppSetting $request 'conString'))).InitialCatalog) 'Db_Tank_V30'
    Assert-Equal "$requestPath.Db_Count" ((New-Object System.Data.SqlClient.SqlConnectionStringBuilder((Get-AppSetting $request 'countDb'))).InitialCatalog) 'Db_Count_V30'
}

$road = Load-Config 'Road.Request\Web.config'
Assert-Equal 'RoadRequest.Db_7road' (Get-ConnectionCatalog $road 'road') 'Db_7road_V30'

$runtimeConfigFiles = @(
    'Center.Service\App.config',
    'Fighting.Service\App.config',
    'Game.Service\App.config',
    'Game.Service\battle.xml'
)
foreach ($relative in $runtimeConfigFiles) {
    $text = Get-Content -LiteralPath (Join-Path $root $relative) -Raw
    if ($text -match '(?<!\d)(9200|9202|9208)(?!\d)') {
        $failures.Add("Legacy runtime endpoint remains in $relative")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "DDTank30 isolation contract failed with $($failures.Count) error(s)."
}
Write-Host 'PASS: DDTank30 runtime config is isolated.'
