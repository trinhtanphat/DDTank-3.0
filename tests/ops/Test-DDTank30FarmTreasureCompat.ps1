$ErrorActionPreference='Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
function Require([bool]$ok,[string]$message){ if(-not $ok){ throw "DDTANK30_FARM_TREASURE_COMPAT_FAIL: $message" } }

$compat = Join-Path $RepoRoot 'Game.Server\Packets\Client\FarmTreasureCompat.cs'
$login = Join-Path $RepoRoot 'Game.Server\Packets\Client\GameUserLoginHandler.cs'
$guild = Join-Path $RepoRoot 'Game.Server\Packets\Client\ConsortiaRichesOfferHandler.cs'
$business = Join-Path $RepoRoot 'Bussiness\PlayerBussiness.cs'
$migration = Join-Path $RepoRoot 'deploy\Migrate-DDTank30FarmTreasure.ps1'

foreach($f in @($compat,$login,$guild,$business,$migration)){ Require (Test-Path -LiteralPath $f) "missing $f" }
$c=Get-Content $compat -Raw
Require ($c -match 'TryHandleFarm') 'farm opcode multiplexer missing'
Require ($c -match 'TryHandleTreasure') 'treasure opcode multiplexer missing'
Require ($c -match 'command == FarmGrow') 'farm grow dispatch missing'
Require ($c -match 'HandleFarmGrow') 'farm grow implementation missing'
Require ($c -match 'HandleTreasureDig') 'treasure dig implementation missing'
Require ($c -match 'seed\.CategoryID != 32') 'farm seed category validation missing'
Require ($c -match 'RemoveTemplate\(templateId, 1\)') 'farm seed consumption missing'
Require ($c -match 'UpdateUserTreasureInfo') 'treasure persistence missing'

Require ((Get-Content $login -Raw) -match 'FarmTreasureCompat\.TryHandleFarm') 'opcode 81 farm multiplex hook missing'
Require ((Get-Content $guild -Raw) -match 'FarmTreasureCompat\.TryHandleTreasure') 'opcode 135 treasure multiplex hook missing'
$b=Get-Content $business -Raw
foreach($method in @('GetSingleFields','AddFields','UpdateFields','GetAllTreasureAward','GetSingleTreasure','GetSingleTreasureData','AddUserTreasureInfo','UpdateUserTreasureInfo','AddTreasureData','UpdateTreasureData')){
    Require ($b -match [regex]::Escape($method)) "PlayerBussiness method missing: $method"
}
$m=Get-Content $migration -Raw
Require ($m -match "TargetDatabase = 'Db_Tank_V30'") 'migration target DB must be Db_Tank_V30'
Require ($m -match 'CategoryID IN \(32,34\)') 'farm template seed migration missing'
Require ($m -match 'Treasure_Award') 'treasure award migration missing'
Require ($m -match '\$cols =') 'Shop_Goods copy must use an explicit compatibility column list'
Write-Host 'DDTANK30_FARM_TREASURE_COMPAT=PASS'
