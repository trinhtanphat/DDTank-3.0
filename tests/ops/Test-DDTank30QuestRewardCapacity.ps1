$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$path = Join-Path $root 'Game.Server\Quests\QuestInventory.cs'

function Require([bool]$condition, [string]$message) {
    if (-not $condition) { throw "DDTANK30_QUEST_REWARD_CAPACITY_FAIL: $message" }
}

Require (Test-Path $path) 'QuestInventory.cs is missing'
$code = Get-Content $path -Raw

Require ($code -match 'CanFitQuestRewards\(PlayerInventory bag, List<ItemInfo> rewards\)') 'stack-aware reward capacity helper is missing'
Require ($code -match 'bag\.GetItems\(\)') 'helper must inspect existing stacks'
Require ($code -match 'reward\.CanStackedTo\(existing\)') 'helper must model real stack compatibility'
Require ($code -match 'existing\.Template\.MaxCount - existing\.Count') 'helper must count residual stack capacity'
Require ($code -match 'emptySlots--') 'helper must account for newly allocated slots'
Require ($code -match '!CanFitQuestRewards\(m_player\.MainBag, mainBg\)') 'main bag preflight must use stack-aware capacity'
Require ($code -match '!CanFitQuestRewards\(m_player\.PropBag, propBg\)') 'prop bag preflight must use stack-aware capacity'
Require ($code -notmatch 'm_player\.PropBag\.GetEmptyCount\(\) < propBg\.Count') 'old empty-slot-only prop bag rejection must be removed'
Require ($code -match 'len \+ temp\.MaxCount > tempCount \? tempCount - len') 'reward chunking must use final randomized count'

Write-Host 'DDTANK30_QUEST_REWARD_CAPACITY=PASS'
