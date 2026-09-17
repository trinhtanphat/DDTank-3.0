$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$apply=Join-Path $repo 'deploy\Apply-DDTank30Instance.ps1'
$example=Join-Path $repo 'deploy\server-instance.example.json'
foreach($p in @($apply,$example)){if(-not(Test-Path $p)){throw "Missing single-source config artifact: $p"}}
$tmp=Join-Path $env:TEMP ('ddtank30-instance-'+[guid]::NewGuid().ToString('N'))
try{
  foreach($rel in @('Game.Service\App.config','Center.Service\App.config','Fighting.Service\App.config','Tank.Request\Web.config','Tank.Request\Tank.Request\Web.config')){
    $dst=Join-Path $tmp $rel; New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent)|Out-Null; Copy-Item (Join-Path $repo $rel) $dst
  }
  $cfg=Get-Content $example -Raw|ConvertFrom-Json
  $cfg.publicHost='203.0.113.77'
  $cfgPath=Join-Path $tmp 'instance.json'
  [IO.File]::WriteAllText($cfgPath,($cfg|ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
  & $apply -ConfigPath $cfgPath -RepoRoot $tmp
  [xml]$game=Get-Content (Join-Path $tmp 'Game.Service\App.config') -Raw
  $settings=@{}; foreach($n in $game.configuration.appSettings.add){$settings[[string]$n.key]=[string]$n.value}
  if($settings.IP-ne'203.0.113.77' -or $settings.Port-ne'9300'){throw 'Game public endpoint was not generated from manifest.'}
  if($settings.LoginServerIp-ne'127.0.0.1' -or $settings.FightServerIp-ne'127.0.0.1'){throw 'Internal DDTank30 hosts must remain loopback.'}
  foreach($rel in @('Tank.Request\Web.config','Tank.Request\Tank.Request\Web.config')){
    $raw=Get-Content (Join-Path $tmp $rel) -Raw
    if($raw -notmatch '203\.0\.113\.77:8083'){throw "$rel did not receive manifest public host."}
    if($raw -match '103\.9\.156\.(181|182)'){throw "$rel retained a production hard-coded host after generation."}
    [xml]$raw|Out-Null
  }
  $runtimeRoot=Join-Path $tmp 'runtime-only-stack'
  foreach($pair in @(
    @('Game.Service\App.config','runtime\game\Road.Service.exe.config'),
    @('Center.Service\App.config','runtime\center\Center.Service.exe.config'),
    @('Fighting.Service\App.config','runtime\fighting\Fighting.Service.exe.config'),
    @('Tank.Request\Web.config','webapps\Request\Web.config')
  )){
    $dst=Join-Path $runtimeRoot $pair[1]; New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent)|Out-Null; Copy-Item (Join-Path $repo $pair[0]) $dst
  }
  $cfg.ddtank30.root=$runtimeRoot
  $runtimeCfg=Join-Path $tmp 'runtime-instance.json'
  [IO.File]::WriteAllText($runtimeCfg,($cfg|ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
  $missingRepo=Join-Path $tmp 'source-checkout-must-not-be-used'
  & $apply -ConfigPath $runtimeCfg -RepoRoot $missingRepo -SkipSourceConfig -ApplyRuntime
  if(Test-Path $missingRepo){throw 'Runtime-only mode touched the source checkout path.'}
  [xml]$runtimeGame=Get-Content (Join-Path $runtimeRoot 'runtime\game\Road.Service.exe.config') -Raw
  $runtimeSettings=@{}; foreach($n in $runtimeGame.configuration.appSettings.add){$runtimeSettings[[string]$n.key]=[string]$n.value}
  if($runtimeSettings.IP-ne'203.0.113.77'){throw 'Runtime-only mode did not update the public game host.'}
  Write-Host 'PASS: DDTank30 runtime-only apply leaves the Git checkout untouched.'
  Write-Host 'PASS: DDTank30 public endpoint is generated from one instance manifest.'
} finally { if(Test-Path $tmp){Remove-Item $tmp -Recurse -Force} }