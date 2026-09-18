$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$p=Join-Path $repo 'deploy\Install-DDTank30Web.ps1'
if(-not(Test-Path $p)){throw 'Missing Install-DDTank30Web.ps1'}
$raw=Get-Content $p -Raw

foreach($token in @(
  'Get-DDTank30Instance.ps1',
  'Apply-DDTank30Instance.ps1',
  'Deploy-DDTank30AdminVip.ps1',
  'DDTank30StaticPool',
  'DDTank30Pool',
  'webapps\Request',
  'db_datareader',
  'db_datawriter',
  'GRANT EXECUTE',
  'inetpub\wwwroot',
  'Tank.Request.csproj',
  '$requestProject',
  'runtime-assets\v30',
  '$runtimeWeb',
  'gunny',
  'Register',
  'admingunny',
  'legacyLoopCss',
  'loop\.jpg',
  'background:#ceebff',
  'gunny\ui\vietnam\swf\core.swf',
  'BEE0D9DB5FD6CFC827E65CFCCA01C229E3666E3B334D91F83543068DA9C65B43',
  'Authoritative core asset hash mismatch',
  'Canonical core asset hash mismatch after webroot copy',
  'legacyBootstrapAliases',
  'gunny\Loading.swf',
  'gunny\config.xml',
  'Legacy bootstrap alias hash mismatch',
  'Patch-DDTank30ClientWindAim.ps1',
  'ClientPatchJavaExe',
  'ClientPatchFfdecJar',
  '$clientInput=$clientTarget',
  '$clientResourceBaseUrl',
  '$clientPatchContract',
  'wind-aim-resource-host-v3',
  'patch_contract',
  'resource_base_url',
  '-ResourceBaseUrl $clientResourceBaseUrl',
  '$clientInputSha',
  '$clientPatchedSha',
  '$clientGenerationRoot',
  'client-overlays\v30\',
  'client-sources\v30\',
  '$clientManifest',
  'manifest.json',
  'input_sha256',
  'output_sha256',
  'Stored client source hash mismatch',
  'ExpectedInputSha256 $clientInputSha',
  '$clientOverlayTemp',
  '[Guid]::NewGuid()',
  'Client generation overlay hash mismatch',
  'Client wind/aim overlay hash mismatch after webroot copy',
  'Build-DDTank30BallListCache.ps1',
  "-ExpectedDatabase 'Db_Tank_V30'",
  '-ExpectedMinimumCount 300',
  'BallList cache missing after rebuild'
)){
  if($raw -notmatch [regex]::Escape($token)){throw "Web installer missing token: $token"}
}

$applyInstanceIndex=$raw.IndexOf('& (Join-Path $PSScriptRoot ''Apply-DDTank30Instance.ps1'')')
$ballListBuilderIndex=$raw.IndexOf('$ballListBuilder=Join-Path $PSScriptRoot ''Build-DDTank30BallListCache.ps1''')
$iisImportIndex=$raw.IndexOf('Import-Module WebAdministration')
if($applyInstanceIndex-lt0 -or $ballListBuilderIndex-lt0 -or $iisImportIndex-lt0){throw 'BallList cache rebuild ordering anchors are missing'}
if(-not($applyInstanceIndex-lt$ballListBuilderIndex -and $ballListBuilderIndex-lt$iisImportIndex)){throw 'BallList cache must rebuild after instance config apply and before IIS provisioning'}

$mirrorIndex=$raw.IndexOf('& robocopy $externalWeb $webRoot /MIR')
$runtimeOverlayIndex=$raw.IndexOf('$runtimeWeb=Join-Path $repo ''runtime-assets\v30''')
$clientOverlayIndex=$raw.IndexOf('$clientRel=''gunny\2.png''')
$adminVipIndex=$raw.IndexOf('$adminVipDeploy=Join-Path $PSScriptRoot ''Deploy-DDTank30AdminVip.ps1''')
if($mirrorIndex-lt0 -or $runtimeOverlayIndex-lt0 -or $clientOverlayIndex-lt0 -or $adminVipIndex-lt0){throw 'Web installer overlay ordering anchors are missing'}
if(-not($mirrorIndex-lt$runtimeOverlayIndex -and $runtimeOverlayIndex-lt$clientOverlayIndex -and $clientOverlayIndex-lt$adminVipIndex)){throw 'Client wind/aim overlay must run after all static/runtime mirrors and before AdminGunny deploy'}

foreach($forbidden in @(
  "[string]`$PublicIp='103.9.156.181'",
  'Request.sln',
  'RenRenAssistant',
  'Tank.SNSAssistant',
  'Instance config apply failed: $LASTEXITCODE',
  '$clientInputExpectedSha',
  '$clientOutputExpectedSha',
  '7BDBF776A53913214A56D8A4A1F06B46588A36EA069E4F5B57D106549D7E2BB5',
  'CFC5902ECD585669084C47D2D89ED6C56433C3458B30828A1661E6B7DCCC3F73'
)){
  if($raw -match [regex]::Escape($forbidden)){throw "Web installer contains forbidden legacy coupling: $forbidden"}
}

Write-Host 'PASS: DDTank30 web installer consumes the single instance manifest and caches client patches by source generation.'
