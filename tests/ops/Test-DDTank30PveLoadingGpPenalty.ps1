$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$pve = Get-Content (Join-Path $root 'Game.Logic\PVEGame.cs') -Raw
$wait = Get-Content (Join-Path $root 'Game.Logic\Actions\WaitPlayerLoadingAction.cs') -Raw
function Require([bool]$ok, [string]$message) { if (-not $ok) { throw $message } }
Require ($wait -match '(?s)GameState\s*==\s*eGameState\.Loading.*?LoadingProcess\s*<\s*100.*?RemovePlayer\(p\.PlayerDetail,\s*false\)') 'loading timeout must remove incomplete players through the normal removal path'
Require ($pve -match '(?s)public override Player RemovePlayer\(IGamePlayer gp, bool isKick\).*?if \(player != null\).*?if \(player\.IsLiving && GameState == eGameState\.Playing\)\s*\{\s*player\.PlayerDetail\.RemoveGP\(gp\.PlayerCharacter\.Grade \* 12\);') 'PvE GP penalty must apply only while a living player leaves an actively Playing game'
Require ($pve -notmatch '(?s)if \(player != null\)\s*\{\s*player\.PlayerDetail\.RemoveGP') 'PvE loading or cleanup removal must not deduct GP unconditionally'
Write-Output 'DDTANK30_PVE_LOADING_GP_PENALTY=PASS'