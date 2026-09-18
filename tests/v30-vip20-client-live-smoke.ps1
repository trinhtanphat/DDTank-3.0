$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$client = Join-Path $root "client\vip20-live"

function Require([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw "V30_VIP20_CLIENT_LIVE_SMOKE_FAIL: $Message" }
}

$give = Get-Content (Join-Path $client "scripts\vip\view\GiveYourselfOpenView.as") -Raw
$controller = Get-Content (Join-Path $client "scripts\vip\VipController.as") -Raw
$socket = Get-Content (Join-Path $client "scripts\ddt\manager\GameSocketOut.as") -Raw
$head = Get-Content (Join-Path $client "scripts\vip\view\VipFrameHead.as") -Raw
$icon = Get-Content (Join-Path $client "scripts\ddt\view\common\VipLevelIcon.as") -Raw
$xml = Get-Content (Join-Path $client "ui\vietnam\xml\vipView.xml") -Raw
$tool = Join-Path $client "tools\patch_v30_live_vip20_client.py"

Require ($give -match 'GOLD_PER_XU\s*:\s*int\s*=\s*1000') 'Gold conversion is missing'
Require ($give -match 'PAY_WITH_GOLD\s*:\s*int\s*=\s*1') 'Gold payment mode is missing'
Require ($give -match 'THREE_MONTH_PAY') '3-month shop price mapping is missing'
Require ($give -match 'getItemPrice\(3\)') '1-year shop price mapping is missing'
Require ($give -match 'Self\.Gold') 'Gold balance is not shown/checked'
Require ($give -match 'sendOpenVip\(PlayerManager\.Instance\.Self\.NickName,this\.days,false,this\._paymentMode\)') 'VIP renewal must send payment mode as fourth field'

Require ($controller -match 'sendOpenVip\(param1:String, param2:int, param3:Boolean = false, param4:int = 0\)') 'VipController four-field contract is missing'
Require ($socket -match 'writeBoolean\(param3\)') 'legacy isBand byte is missing'
Require ($socket -match 'writeByte\(param4\)') 'paymentMode byte is missing'

Require ($head -match '7800000') 'VIP20 EXP floor is missing'
Require ($head -match 'level >= 20') 'VIP20 MAX logic is missing'
Require ($head -match 'Math\.min\(required,PlayerManager\.Instance\.Self\.VIPExp - floorExp\)') 'non-negative bounded progress logic is missing'

Require ($icon -match 'VIPLevel < 20') 'VIP20 tooltip ceiling is missing'
Require ($icon -match 'Math\.min\(9,this\._level\)') 'legacy artwork clamp is missing'
Require ($xml -match 'GiveYourselfOpenView\.goldModeBtn') 'Gold-mode UI style is missing'
Require (Test-Path $tool) 'strict live-client patch script is missing'

Write-Host 'V30_VIP20_CLIENT_LIVE_SMOKE=PASS'