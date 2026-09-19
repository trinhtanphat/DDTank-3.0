param(
    [Parameter(Mandatory = $true)]
    [string]$InputEncodedClient,
    [Parameter(Mandatory = $true)]
    [string]$OutputEncodedClient,
    [Parameter(Mandatory = $true)]
    [string]$JavaExe,
    [Parameter(Mandatory = $true)]
    [string]$FfdecJar,
    [string]$WorkRoot = '',
    [string]$ExpectedInputSha256 = '',
    [string]$ExpectedOutputSha256 = '',
    [string]$ResourceBaseUrl = ''
)

$ErrorActionPreference = 'Stop'

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Require([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Quote-ProcessArgument([string]$Value) {
    return '"' + $Value.Replace('"', '\"') + '"'
}

function Invoke-Java([string[]]$Arguments) {
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $JavaExe
    $psi.Arguments = (($Arguments | ForEach-Object { Quote-ProcessArgument $_ }) -join ' ')
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        $nl = [Environment]::NewLine
        throw ('Java/FFDec failed with exit ' + $process.ExitCode + '.' + $nl + 'STDOUT:' + $nl + $stdout + $nl + 'STDERR:' + $nl + $stderr)
    }
}

function Decode-DDTank30AlmClient([string]$InputPath, [string]$OutputSwf) {
    $encoded = [IO.File]::ReadAllBytes($InputPath)
    Require ($encoded.Length -gt 142) 'Encoded client is too small to be an ALM-wrapped SWF.'
    Require ([Text.Encoding]::ASCII.GetString($encoded, 0, 3) -eq 'ALM') 'Encoded client does not start with ALM.'

    $decoded = New-Object byte[] ($encoded.Length - 18)
    $decoded[0] = 67
    $decoded[1] = 87
    $decoded[2] = 83
    [Array]::Copy($encoded, $encoded.Length - 121, $decoded, 3, 121)
    [Array]::Copy($encoded, 21, $decoded, 124, $encoded.Length - 142)

    Require ([Text.Encoding]::ASCII.GetString($decoded, 0, 3) -eq 'CWS') 'Decoded client does not start with CWS.'
    [IO.File]::WriteAllBytes($OutputSwf, $decoded)
}

function Encode-DDTank30AlmClient([string]$OriginalEncodedPath, [string]$InputSwf, [string]$OutputPath) {
    $original = [IO.File]::ReadAllBytes($OriginalEncodedPath)
    $raw = [IO.File]::ReadAllBytes($InputSwf)

    Require ([Text.Encoding]::ASCII.GetString($original, 0, 3) -eq 'ALM') 'Original encoded client does not start with ALM.'
    Require ([Text.Encoding]::ASCII.GetString($raw, 0, 3) -eq 'CWS') 'Patched SWF does not start with CWS.'
    Require ($raw.Length -gt 124) 'Patched SWF is too small.'

    $encoded = New-Object byte[] ($raw.Length + 18)
    [Array]::Copy($original, 0, $encoded, 0, 21)
    [Array]::Copy($raw, 124, $encoded, 21, $raw.Length - 124)
    [Array]::Copy($raw, 3, $encoded, $encoded.Length - 121, 121)
    [IO.File]::WriteAllBytes($OutputPath, $encoded)
}

$InputEncodedClient = [IO.Path]::GetFullPath($InputEncodedClient)
$OutputEncodedClient = [IO.Path]::GetFullPath($OutputEncodedClient)
$JavaExe = [IO.Path]::GetFullPath($JavaExe)
$FfdecJar = [IO.Path]::GetFullPath($FfdecJar)
$resourceBase = $ResourceBaseUrl.Trim()
if ($resourceBase) {
    Require ($resourceBase -match '^https?://') 'ResourceBaseUrl must use http:// or https://.'
    Require (-not $resourceBase.Contains('"')) 'ResourceBaseUrl must not contain a double quote.'
    Require (-not $resourceBase.Contains("`r") -and -not $resourceBase.Contains("`n")) 'ResourceBaseUrl must be a single line.'
    if (-not $resourceBase.EndsWith('/')) { $resourceBase += '/' }
}

Require (Test-Path -LiteralPath $InputEncodedClient) "Input client not found: $InputEncodedClient"
Require (Test-Path -LiteralPath $JavaExe) "Java executable not found: $JavaExe"
Require (Test-Path -LiteralPath $FfdecJar) "FFDec jar not found: $FfdecJar"

$inputSha = Get-Sha256 $InputEncodedClient
if ($ExpectedInputSha256) {
    Require ($inputSha -eq $ExpectedInputSha256.ToUpperInvariant()) "Input SHA256 mismatch. Expected=$ExpectedInputSha256 Actual=$inputSha"
}

if (-not $WorkRoot) {
    $WorkRoot = Join-Path ([IO.Path]::GetTempPath()) ('ddtank30-client-wind-aim-' + [Guid]::NewGuid().ToString('N'))
}
$WorkRoot = [IO.Path]::GetFullPath($WorkRoot)
if (Test-Path -LiteralPath $WorkRoot) { Remove-Item -LiteralPath $WorkRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $WorkRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $OutputEncodedClient -Parent) | Out-Null

$decodedSwf = Join-Path $WorkRoot 'client.decoded.swf'
$patchedSwf = Join-Path $WorkRoot 'client.patched.swf'
$roundTripSwf = Join-Path $WorkRoot 'client.roundtrip.swf'
$exportRoot = Join-Path $WorkRoot 'export'
$patchRoot = Join-Path $WorkRoot 'patch'
$verifyRoot = Join-Path $WorkRoot 'verify'

Decode-DDTank30AlmClient $InputEncodedClient $decodedSwf

$selectedClasses = 'game.objects.GameLocalPlayer,game.view.VaneView,ddt.manager.PathManager,game.view.Bomb,ddt.utils.RequestVairableCreater'
Invoke-Java @('-jar', $FfdecJar, '-onerror', 'abort', '-selectclass', $selectedClasses, '-export', 'script', $exportRoot, $decodedSwf)

$gameLocalSource = Join-Path $exportRoot 'scripts\game\objects\GameLocalPlayer.as'
$vaneSource = Join-Path $exportRoot 'scripts\game\view\VaneView.as'
$pathManagerSource = Join-Path $exportRoot 'scripts\ddt\manager\PathManager.as'
$bombSource = Join-Path $exportRoot 'scripts\game\view\Bomb.as'
$requestVariableSource = Join-Path $exportRoot 'scripts\ddt\utils\RequestVairableCreater.as'
Require (Test-Path -LiteralPath $gameLocalSource) 'FFDec did not export GameLocalPlayer.as.'
Require (Test-Path -LiteralPath $vaneSource) 'FFDec did not export VaneView.as.'
Require (Test-Path -LiteralPath $pathManagerSource) 'FFDec did not export PathManager.as.'
Require (Test-Path -LiteralPath $bombSource) 'FFDec did not export Bomb.as.'
Require (Test-Path -LiteralPath $requestVariableSource) 'FFDec did not export RequestVairableCreater.as.'

New-Item -ItemType Directory -Force -Path (Join-Path $patchRoot 'game\objects'), (Join-Path $patchRoot 'game\view'), (Join-Path $patchRoot 'ddt\manager'), (Join-Path $patchRoot 'ddt\utils') | Out-Null
$gameLocalPatched = Join-Path $patchRoot 'game\objects\GameLocalPlayer.as'
$vanePatched = Join-Path $patchRoot 'game\view\VaneView.as'
$pathManagerPatched = Join-Path $patchRoot 'ddt\manager\PathManager.as'
$bombPatched = Join-Path $patchRoot 'game\view\Bomb.as'
$requestVariablePatched = Join-Path $patchRoot 'ddt\utils\RequestVairableCreater.as'
Copy-Item -LiteralPath $gameLocalSource -Destination $gameLocalPatched -Force
Copy-Item -LiteralPath $vaneSource -Destination $vanePatched -Force
Copy-Item -LiteralPath $pathManagerSource -Destination $pathManagerPatched -Force
Copy-Item -LiteralPath $bombSource -Destination $bombPatched -Force
Copy-Item -LiteralPath $requestVariableSource -Destination $requestVariablePatched -Force

$gameLocal = [IO.File]::ReadAllText($gameLocalPatched, [Text.Encoding]::UTF8)
$gameLocal = $gameLocal.Replace('_map', 'map')

$walkProtectedPattern = 'if\(![^\r\n]+&& this\.localPlayer\.isAttacking && \(this\._keyDownTime == 0 \|\| getTimer\(\) - this\._keyDownTime > MAX_MOVE_TIME\)\)'
$walkReplacement = 'if(this.localPlayer.isAttacking && (this._keyDownTime == 0 || getTimer() - this._keyDownTime > MAX_MOVE_TIME))'
$walkBefore = $gameLocal
$gameLocal = [Regex]::Replace($gameLocal, $walkProtectedPattern, $walkReplacement, 1)
Require ($gameLocal -ne $walkBefore) 'Could not normalize the protected movement guard in GameLocalPlayer.'

$turnStart = $gameLocal.IndexOf('      private function __turnLeft() : void')
$turnEnd = $gameLocal.IndexOf('      protected function walk() : void', $turnStart)
Require ($turnStart -ge 0 -and $turnEnd -gt $turnStart) 'Could not locate turn-left/turn-right method boundaries.'

$turnMethods = @'
      private function __turnLeft() : void
      {
         if(this._isShooting)
         {
            if(this.localPlayer.isAttacking && this._shootCount < this.localPlayer.shootCount && info.direction != -1)
            {
               info.direction = -1;
               GameInSocketOut.sendGameCMDDirection(info.direction);
            }
            return;
         }
         if(info.direction == 1)
         {
            info.direction = -1;
            if(this._keyDownTime == 0)
            {
               this._keyDownTime = getTimer();
            }
         }
         this.walk();
      }
      
      private function __turnRight() : void
      {
         if(this._isShooting)
         {
            if(this.localPlayer.isAttacking && this._shootCount < this.localPlayer.shootCount && info.direction != 1)
            {
               info.direction = 1;
               GameInSocketOut.sendGameCMDDirection(info.direction);
            }
            return;
         }
         if(info.direction == -1)
         {
            info.direction = 1;
            if(this._keyDownTime == 0)
            {
               this._keyDownTime = getTimer();
            }
         }
         this.walk();
      }
      
'@
$gameLocal = $gameLocal.Substring(0, $turnStart) + $turnMethods + $gameLocal.Substring($turnEnd)

$shootStart = $gameLocal.IndexOf('      protected function __sendShoot(param1:LivingEvent) : void')
$timerStart = $gameLocal.IndexOf('      private function __shootTimer(param1:Event) : void', $shootStart)
Require ($shootStart -ge 0 -and $timerStart -gt $shootStart) 'Could not locate shoot method boundaries.'

$shootBlock = $gameLocal.Substring($shootStart, $timerStart - $shootStart)
$attackReset = '         this.localPlayer.isAttacking = false;'
Require ($shootBlock.Contains($attackReset)) 'Expected first-shot isAttacking reset was not found.'
$shootBlock = $shootBlock.Replace($attackReset, '')

$meleeElse = $shootBlock.LastIndexOf('         else')
$meleeBrace = if ($meleeElse -ge 0) { $shootBlock.IndexOf('{', $meleeElse) } else { -1 }
Require ($meleeElse -ge 0 -and $meleeBrace -gt $meleeElse) 'Could not locate the melee branch in __sendShoot.'
$shootBlock = $shootBlock.Insert($meleeBrace + 1, [Environment]::NewLine + '            this.localPlayer.isAttacking = false;')
$gameLocal = $gameLocal.Substring(0, $shootStart) + $shootBlock + $gameLocal.Substring($timerStart)

$timerStart = $gameLocal.IndexOf('      private function __shootTimer(param1:Event) : void')
$nextTurnStart = $gameLocal.IndexOf('      override protected function __beginNewTurn', $timerStart)
Require ($timerStart -ge 0 -and $nextTurnStart -gt $timerStart) 'Could not locate __shootTimer boundaries.'

$shootTimer = @'
      private function __shootTimer(param1:Event) : void
      {
         var _loc2_:Point = null;
         var _loc3_:Number = NaN;
         var _loc4_:int = 0;
         if(Boolean(this.localPlayer) && Boolean(this.localPlayer.isLiving) && this._shootCount < this.localPlayer.shootCount)
         {
            _loc2_ = shootPoint();
            _loc3_ = this.localPlayer.calcBombAngle();
            _loc4_ = this.localPlayer.force;
            GameInSocketOut.sendGameCMDShoot(_loc2_.x,_loc2_.y,_loc4_,_loc3_);
            MapView(map).gameView.setRecordRotation();
            ++this._shootCount;
            if(this._shootCount >= this.localPlayer.shootCount)
            {
               this.localPlayer.isAttacking = false;
               this._shootTimer.stop();
            }
         }
      }
      
'@
$gameLocal = $gameLocal.Substring(0, $timerStart) + $shootTimer + $gameLocal.Substring($nextTurnStart)
[IO.File]::WriteAllText($gameLocalPatched, $gameLocal, (New-Object Text.UTF8Encoding($false)))

$vane = [IO.File]::ReadAllText($vanePatched, [Text.Encoding]::UTF8)
Require ($vane.Contains('            param3 = [true,0,0,0];')) 'Expected VaneView fallback tuple was not found.'
$vane = $vane.Replace('            param3 = [true,0,0,0];', '            param3 = [param1 >= 0,0,0,0];')

$zeroPattern = 'if\(param3\[1\] == 0 && param3\[2\] == 0 && param3\[3\] == 0\)\s*\{\s*this\._zeroTxt\.x = this\.windPicBmp\.x;'
$zeroReplacement = @'
if(param3[1] == 0 && param3[2] == 0 && param3[3] == 0)
         {
            this._zeroTxt.text = this.addZero(param1);
            this._zeroTxt.x = this.windPicBmp.x;
'@
$zeroBefore = $vane
$vane = [Regex]::Replace($vane, $zeroPattern, $zeroReplacement, 1)
Require ($vane -ne $zeroBefore) 'Could not patch VaneView numeric fallback.'
[IO.File]::WriteAllText($vanePatched, $vane, (New-Object Text.UTF8Encoding($false)))

# Ruffle compatibility: EventDispatcher initialization writes the "target" property.
# Bomb exposes a computed getter named target without a setter in the legacy client,
# which Ruffle rejects with Error #1074 before any projectile can be rendered.
# Keep the computed getter semantics and accept the constructor-time write as a no-op.
$bomb = [IO.File]::ReadAllText($bombPatched, [Text.Encoding]::UTF8)
Require ($bomb -match 'public function get target\(\) : Point') 'Bomb target getter was not found.'
if ($bomb -notmatch 'public function set target\(param1:Point\) : void') {
    $bombSetterMarker = '      public function get isCritical() : Boolean'
    Require ($bomb.Contains($bombSetterMarker)) 'Could not locate Bomb target setter insertion point.'
    $nl = [Environment]::NewLine
    $bombSetter = '      public function set target(param1:Point) : void' + $nl + '      {' + $nl + '      }' + $nl + '      ' + $nl
    $bomb = $bomb.Replace($bombSetterMarker, $bombSetter + $bombSetterMarker)
}
[IO.File]::WriteAllText($bombPatched, $bomb, (New-Object Text.UTF8Encoding($false)))

if ($resourceBase) {
    $pathManager = [IO.File]::ReadAllText($pathManagerPatched, [Text.Encoding]::UTF8)
    $setupPattern = 'info\s*=\s*param1;\s*SITE_MAIN\s*=\s*info\.SITE;'
    $setupReplacement = 'info = param1;' + [Environment]::NewLine + '         info.SITE = "' + $resourceBase + '";' + [Environment]::NewLine + '         SITE_MAIN = info.SITE;'
    $pathBefore = $pathManager
    $pathManager = [Regex]::Replace($pathManager, $setupPattern, $setupReplacement, 1)
    Require ($pathManager -ne $pathBefore) 'Could not patch PathManager.setup resource base.'
    [IO.File]::WriteAllText($pathManagerPatched, $pathManager, (New-Object Text.UTF8Encoding($false)))
}


# The legacy client creates SelfInfo before Login.ashx populates the numeric player ID.
# BasePlayer.ID is Number, so its uninitialized value serializes as NaN. Keep the
# authenticated ID after login, but send a deterministic neutral ID before login.
$requestVariable = [IO.File]::ReadAllText($requestVariablePatched, [Text.Encoding]::UTF8)
$unsafeSelfId = '         _loc2_["selfid"] = PlayerManager.Instance.Self.ID;'
$safeSelfId = '         _loc2_["selfid"] = isNaN(PlayerManager.Instance.Self.ID) ? 0 : PlayerManager.Instance.Self.ID;'
Require ($requestVariable.Contains($unsafeSelfId) -or $requestVariable.Contains($safeSelfId)) 'RequestVairableCreater selfid assignment was not found.'
if ($requestVariable.Contains($unsafeSelfId)) {
    $requestVariable = $requestVariable.Replace($unsafeSelfId, $safeSelfId)
}
[IO.File]::WriteAllText($requestVariablePatched, $requestVariable, (New-Object Text.UTF8Encoding($false)))

Invoke-Java @('-jar', $FfdecJar, '-onerror', 'abort', '-importScript', $decodedSwf, $patchedSwf, $patchRoot)
Require (Test-Path -LiteralPath $patchedSwf) 'FFDec did not produce the patched SWF.'

Invoke-Java @('-jar', $FfdecJar, '-onerror', 'abort', '-selectclass', $selectedClasses, '-export', 'script', $verifyRoot, $patchedSwf)

$verifiedGameLocal = [IO.File]::ReadAllText((Join-Path $verifyRoot 'scripts\game\objects\GameLocalPlayer.as'), [Text.Encoding]::UTF8)
$verifiedVane = [IO.File]::ReadAllText((Join-Path $verifyRoot 'scripts\game\view\VaneView.as'), [Text.Encoding]::UTF8)
$verifiedPathManager = [IO.File]::ReadAllText((Join-Path $verifyRoot 'scripts\ddt\manager\PathManager.as'), [Text.Encoding]::UTF8)
$verifiedBomb = [IO.File]::ReadAllText((Join-Path $verifyRoot 'scripts\game\view\Bomb.as'), [Text.Encoding]::UTF8)
$verifiedRequestVariable = [IO.File]::ReadAllText((Join-Path $verifyRoot 'scripts\ddt\utils\RequestVairableCreater.as'), [Text.Encoding]::UTF8)

Require ($verifiedBomb -match 'public function get target\(\) : Point') 'Patched SWF lost the Bomb target getter.'
Require ($verifiedBomb -match 'public function set target\(param1:Point\) : void') 'Patched SWF is missing the Ruffle-safe Bomb target setter.'
Require ($verifiedRequestVariable.Contains($safeSelfId)) 'Patched SWF is missing the pre-login selfid NaN guard.'
Require ($verifiedGameLocal -match 'if\(this\._isShooting\)[\s\S]*this\._shootCount < this\.localPlayer\.shootCount[\s\S]*sendGameCMDDirection') 'Patched SWF is missing mid-volley left/right direction logic.'
Require ($verifiedGameLocal -match '\+\+this\._shootCount;[\s\S]{0,300}if\(this\._shootCount >= this\.localPlayer\.shootCount\)[\s\S]{0,300}this\._shootTimer\.stop\(\)') 'Patched SWF is missing final-shot cleanup.'
Require ($verifiedGameLocal -match '_loc2_ = shootPoint\(\);[\s\S]{0,250}sendGameCMDShoot') 'Patched SWF does not recompute the muzzle point for each projectile.'
Require ($verifiedVane -match 'param3 = \[param1 >= 0,0,0,0\]') 'Patched SWF is missing wind-direction fallback.'
Require ($verifiedVane -match 'this\._zeroTxt\.text = this\.addZero\(param1\)') 'Patched SWF is missing numeric wind fallback.'
if ($resourceBase) {
    $resourceLiteral = [Regex]::Escape('info.SITE = "' + $resourceBase + '";')
    Require ($verifiedPathManager -match $resourceLiteral) 'Patched SWF is missing the canonical resource-base override.'
}

Encode-DDTank30AlmClient $InputEncodedClient $patchedSwf $OutputEncodedClient
Decode-DDTank30AlmClient $OutputEncodedClient $roundTripSwf

$patchedSwfSha = Get-Sha256 $patchedSwf
$roundTripSha = Get-Sha256 $roundTripSwf
Require ($patchedSwfSha -eq $roundTripSha) "ALM encode/decode round-trip mismatch. Patched=$patchedSwfSha RoundTrip=$roundTripSha"

$outputSha = Get-Sha256 $OutputEncodedClient
if ($ExpectedOutputSha256) {
    Require ($outputSha -eq $ExpectedOutputSha256.ToUpperInvariant()) "Output SHA256 mismatch. Expected=$ExpectedOutputSha256 Actual=$outputSha"
}

Write-Host 'DDTANK30_CLIENT_WIND_AIM_PATCH=PASS'
Write-Host "INPUT_SHA256=$inputSha"
Write-Host "PATCHED_SWF_SHA256=$patchedSwfSha"
Write-Host "OUTPUT_SHA256=$outputSha"
if ($resourceBase) { Write-Host "RESOURCE_BASE_URL=$resourceBase" }
Write-Host "OUTPUT=$OutputEncodedClient"
