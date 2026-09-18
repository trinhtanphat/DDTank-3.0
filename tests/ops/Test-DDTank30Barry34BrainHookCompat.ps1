$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$commit = '73e189aef774b1f2eead70979c97b53619db07aa'
$provPath = Join-Path $repo 'Game.Logic\BARRY34-BRAIN-HOOK-COMPAT.md'
if (-not (Test-Path -LiteralPath $provPath)) { throw 'Missing Barry34 brain-hook provenance.' }
if ((Get-Content $provPath -Raw) -notmatch [regex]::Escape($commit)) { throw 'Barry34 reference commit missing from provenance.' }

$abrain = Get-Content (Join-Path $repo 'Game.Logic\AI\ABrain.cs') -Raw
foreach ($signature in @(
    'public virtual void OnDie\(\)',
    'public virtual void OnAfterTakedBomb\(\)',
    'public virtual void OnAfterTakedFrozen\(\)',
    'public virtual void OnAfterTakeDamage\(Living source\)'
)) {
    if ($abrain -notmatch $signature) { throw "ABrain compatibility hook missing: $signature" }
}

$living = Get-Content (Join-Path $repo 'Game.Logic\Phy\Object\Living.cs') -Raw
foreach ($signature in @(
    'public virtual void OnAfterTakedBomb\(\)',
    'public virtual void OnAfterTakedFrozen\(\)',
    'public virtual void OnAfterTakeDamage\(Living source\)'
)) {
    if ($living -notmatch $signature) { throw "Living compatibility hook missing: $signature" }
}

foreach ($name in @('SimpleNpc.cs','SimpleBoss.cs')) {
    $raw = Get-Content (Join-Path $repo "Game.Logic\Phy\Object\$name") -Raw
    foreach ($call in @(
        'm_ai.OnDie\(\)',
        'm_ai.OnAfterTakedBomb\(\)',
        'm_ai.OnAfterTakedFrozen\(\)',
        'm_ai.OnAfterTakeDamage\(source\)'
    )) {
        if ($raw -notmatch $call) { throw "$name is missing brain callback $call" }
    }

    $delayMethod = [regex]::Match($raw,'public override void Die\(int delay\)\s*\{(?<body>.*?)\n\s*\}',[Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $delayMethod.Success) { throw "Could not inspect delayed death in $name." }
    if ($delayMethod.Groups['body'].Value -match 'm_ai\.OnDie\(') { throw "$name dispatches OnDie during delayed scheduling; this would double-fire." }
}

$npc = Get-Content (Join-Path $repo 'Game.Logic\Phy\Object\SimpleNpc.cs') -Raw
$boss = Get-Content (Join-Path $repo 'Game.Logic\Phy\Object\SimpleBoss.cs') -Raw
$opts = [Text.RegularExpressions.RegexOptions]::Singleline
if (-not [regex]::IsMatch($npc,'bool wasLiving = IsLiving;.*?base\.Die\(\);.*?if \(wasLiving && !IsLiving\).*?m_ai\.OnDie\(\)',$opts)) {
    throw 'SimpleNpc death callback is not guarded by the actual living-to-dead transition.'
}
if (-not [regex]::IsMatch($boss,'bool wasLiving = IsLiving;.*?base\.Die\(\);.*?if \(wasLiving && !IsLiving\).*?m_ai\.OnDie\(\)',$opts)) {
    throw 'SimpleBoss death callback is not guarded by the actual living-to-dead transition.'
}

$bomb = Get-Content (Join-Path $repo 'Game.Logic\Phy\Object\SimpleBomb.cs') -Raw
if ($bomb -notmatch 'new LivingAfterShootedAction\(m_owner, p, \(int\)\(\(m_lifeTime \+ 1\) \* 1000\)\)') {
    throw 'Bomb damage callback must be delayed until after bomb animation lifetime.'
}
if ($bomb -notmatch 'new LivingAfterShootedFrozen\(p, \(int\)\(\(m_lifeTime \+ 1\) \* 1000\)\)') {
    throw 'Frozen callback must be delayed until after bomb animation lifetime.'
}

$shotAction = Get-Content (Join-Path $repo 'Game.Logic\Actions\LivingAfterShootedAction.cs') -Raw
if ($shotAction -notmatch 'm_target\.OnAfterTakedBomb\(\);' -or $shotAction -notmatch 'm_target\.OnAfterTakeDamage\(m_owner\);') {
    throw 'Post-shot action does not dispatch both bomb and damage callbacks.'
}
$frozenAction = Get-Content (Join-Path $repo 'Game.Logic\Actions\LivingAfterShootedFrozen.cs') -Raw
if ($frozenAction -notmatch 'm_target\.OnAfterTakedFrozen\(\);') {
    throw 'Post-frozen action does not dispatch the frozen callback.'
}

$project = Get-Content (Join-Path $repo 'Game.Logic\Game.Logic.csproj') -Raw
foreach ($include in @('Actions\LivingAfterShootedAction.cs','Actions\LivingAfterShootedFrozen.cs')) {
    if ($project -notmatch [regex]::Escape("Compile Include=`"$include`"")) { throw "Game.Logic.csproj missing $include" }
}

Write-Host 'DDTANK30_BARRY34_BRAIN_HOOK_COMPAT=PASS hooks=4 death=exact-once callbacks=delayed'
