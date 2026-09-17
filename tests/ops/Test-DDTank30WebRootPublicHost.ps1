$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$apply=Join-Path $repo 'deploy\Apply-DDTank30Instance.ps1'
$example=Join-Path $repo 'deploy\server-instance.example.json'
$tmp=Join-Path $env:TEMP ('ddtank30-webroot-'+[guid]::NewGuid().ToString('N'))
try {
  $stack=Join-Path $tmp 'stack'
  foreach($pair in @(
    @('Game.Service\App.config','runtime\game\Road.Service.exe.config'),
    @('Center.Service\App.config','runtime\center\Center.Service.exe.config'),
    @('Fighting.Service\App.config','runtime\fighting\Fighting.Service.exe.config'),
    @('Tank.Request\Web.config','webapps\Request\Web.config'),
    @('Tank.Request\Web.config','webroot\Request\Web.config'),
    @('Tank.Request\Tank.Request\Web.config','webroot\Request\Tank.Request\Web.config')
  )) { $dst=Join-Path $stack $pair[1]; New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent)|Out-Null; Copy-Item (Join-Path $repo $pair[0]) $dst }
  New-Item -ItemType Directory -Force -Path (Join-Path $stack 'webroot\gunny'),(Join-Path $stack 'webroot\admingunny')|Out-Null
  [IO.File]::WriteAllText((Join-Path $stack 'webroot\gunny\login.htm'),'<a href="http://14.225.210.178/register/">Dang ky nhanh</a><a href="http://14.225.210.178:90/reg/forgotpass.html?x=1">Forgot</a>')
  [IO.File]::WriteAllText((Join-Path $stack 'webroot\gunny\config.xml'),'<ROOT><SITE value="http://14.225.210.178/Resource/"/><FIRSTPAGE value="http://14.225.210.178:9001/gunny/"/><REGISTER value="http://14.225.210.178:9001/"/><REQUEST_PATH value="http://14.225.210.178/request/"/><LOGIN_PATH value="http://14.225.210.178/gunny/"/><FILL_PATH value="http://14.225.210.178/gunny/"/></ROOT>')
  [IO.File]::WriteAllText((Join-Path $stack 'webroot\gunny\Web.config'),'<configuration><appSettings><add key="LoginUrl" value="http://14.225.210.178/Request/createLogin.aspx"/><add key="LoginOnUrl" value="http://14.225.210.178/gunny/login.htm"/><add key="FlashUrl" value="http://14.225.210.178/gunny/index.aspx"/></appSettings></configuration>')
  [IO.File]::WriteAllText((Join-Path $stack 'webroot\admingunny\Web.config'),'<configuration><appSettings><add key="Resource" value="http://14.225.210.178/Resource/"/><add key="ServerIP" value="14.225.210.178"/></appSettings><system.serviceModel><client><endpoint address="net.tcp://14.225.210.178:2009/" contract="CenterService.ICenterService"/><endpoint address="http://14.225.210.178/admingunny/Flash_Port/PassPort.asmx" contract="WebLogin.PassPortSoap"/></client></system.serviceModel></configuration>')
  foreach($rel in @('webroot\Request\Web.config','webroot\Request\Tank.Request\Web.config')) { $p=Join-Path $stack $rel; $raw=Get-Content $p -Raw; $raw=[regex]::Replace($raw,'(<add\s+key="AdminIP"\s+value=")[^"]*(")','$114.225.210.178|192.168.0.19$2'); $raw=[regex]::Replace($raw,'(<add\s+key="SentRewardIP"\s+value=")[^"]*(")','$114.225.210.178$2'); $raw=[regex]::Replace($raw,'(<endpoint\b(?=[^>]*contract="CenterService\.ICenterService")[^>]*address=")[^"]*(")','$1net.tcp://14.225.210.178:2009/$2'); [IO.File]::WriteAllText($p,$raw) }
  $cfg=Get-Content $example -Raw|ConvertFrom-Json; $cfg.publicHost='203.0.113.77'; $cfg.ddtank30.root=$stack; $cfgPath=Join-Path $tmp 'instance.json'; [IO.File]::WriteAllText($cfgPath,($cfg|ConvertTo-Json -Depth 8))
  & $apply -ConfigPath $cfgPath -RepoRoot (Join-Path $tmp 'unused-source') -SkipSourceConfig -ApplyRuntime
  $targets=@('webroot\gunny\login.htm','webroot\gunny\config.xml','webroot\gunny\Web.config','webroot\Request\Web.config','webroot\Request\Tank.Request\Web.config','webroot\admingunny\Web.config')
  foreach($rel in $targets){$raw=Get-Content (Join-Path $stack $rel) -Raw; if($raw -match '14\.225\.210\.178'){throw "$rel retained legacy public host"}}
  $login=Get-Content (Join-Path $stack 'webroot\gunny\login.htm') -Raw; if($login -notmatch '203\.0\.113\.77:8083/Register/'){throw 'Quick registration did not use manifest web endpoint.'}
  $admin=Get-Content (Join-Path $stack 'webroot\admingunny\Web.config') -Raw; if($admin -notmatch 'net\.tcp://127\.0\.0\.1:9302/'){throw 'Admin Center endpoint did not remain loopback.'}
  Write-Host 'PASS: DDTank30 legacy webroot is generated from the manifest and has no stale public host.'
} finally { if(Test-Path $tmp){Remove-Item $tmp -Recurse -Force} }
