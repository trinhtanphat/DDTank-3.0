$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$patcher = Join-Path $repoRoot 'deploy\Patch-DDTank30ClientWindAim.ps1'

if (-not (Test-Path -LiteralPath $patcher)) {
    throw "Client wind/aim patcher missing: $patcher"
}

$text = [IO.File]::ReadAllText($patcher, [Text.Encoding]::UTF8)

function Require-Text([string]$Needle, [string]$Message) {
    if (-not $text.Contains($Needle)) {
        throw $Message
    }
}

function Require-Regex([string]$Pattern, [string]$Message) {
    if ($text -notmatch $Pattern) {
        throw $Message
    }
}

foreach ($parameter in @(
    '[string]$InputEncodedClient',
    '[string]$OutputEncodedClient',
    '[string]$JavaExe',
    '[string]$FfdecJar',
    '[string]$ExpectedInputSha256',
    '[string]$ExpectedOutputSha256',
    '[string]$ResourceBaseUrl'
)) {
    Require-Text $parameter "Missing patcher parameter contract: $parameter"
}

Require-Text 'Decode-DDTank30AlmClient' 'ALM decode helper missing.'
Require-Text 'Encode-DDTank30AlmClient' 'ALM encode helper missing.'
Require-Text '[Text.Encoding]::ASCII.GetString($encoded, 0, 3) -eq ''ALM''' 'ALM input signature guard missing.'
Require-Text '[Text.Encoding]::ASCII.GetString($decoded, 0, 3) -eq ''CWS''' 'Decoded CWS signature guard missing.'
Require-Text '[Array]::Copy($encoded, $encoded.Length - 121, $decoded, 3, 121)' 'ALM trailer restoration contract missing.'
Require-Text '[Array]::Copy($encoded, 21, $decoded, 124, $encoded.Length - 142)' 'ALM payload restoration contract missing.'
Require-Text '[Array]::Copy($raw, 124, $encoded, 21, $raw.Length - 124)' 'ALM payload encode contract missing.'
Require-Text '[Array]::Copy($raw, 3, $encoded, $encoded.Length - 121, 121)' 'ALM trailer encode contract missing.'

Require-Text '''game.objects.GameLocalPlayer,game.view.VaneView,ddt.manager.PathManager''' 'Expected client classes are not selected for patching.'
Require-Text 'sendGameCMDDirection(info.direction);' 'Mid-volley left/right direction packet contract missing.'
Require-Text 'this._shootCount < this.localPlayer.shootCount' 'Remaining-ammo direction guard missing.'
Require-Text '_loc2_ = shootPoint();' 'Per-projectile muzzle-point recomputation missing.'
Require-Text '_loc3_ = this.localPlayer.calcBombAngle();' 'Per-projectile angle recomputation missing.'
Require-Text '_loc4_ = this.localPlayer.force;' 'Per-projectile force read missing.'
Require-Text 'if(this._shootCount >= this.localPlayer.shootCount)' 'Final-projectile boundary guard missing.'
Require-Text 'this.localPlayer.isAttacking = false;' 'Final-projectile attacking-state cleanup missing.'
Require-Text 'this._shootTimer.stop();' 'Final-projectile timer stop missing.'

Require-Text 'param3 = [param1 >= 0,0,0,0];' 'Wind direction fallback contract missing.'
Require-Text 'this._zeroTxt.text = this.addZero(param1);' 'Numeric wind display fallback contract missing.'
Require-Text '$pathManagerSource' 'PathManager export contract missing.'
Require-Text 'info.SITE = "' 'Resource host override assignment missing.'
Require-Text 'ResourceBaseUrl must use http:// or https://.' 'Resource URL validation missing.'
Require-Text 'RESOURCE_BASE_URL=' 'Resource-base verification output missing.'

Require-Regex '\$patchedSwfSha\s+-eq\s+\$roundTripSha' 'ALM round-trip SHA verification missing.'
Require-Text 'DDTANK30_CLIENT_WIND_AIM_PATCH=PASS' 'Success marker missing.'

if ($text -match '(?i)C:[\\/]+Gunny-DDTank30|103\.9\.156\.181') {
    throw 'Patcher must not hard-code the production server path or IP.'
}

Write-Host 'DDTANK30_CLIENT_WIND_AIM_PATCHER_CONTRACT=PASS'
