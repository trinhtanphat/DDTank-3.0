$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$p=Join-Path $repo 'deploy\Install-DDTank30Web.ps1'
if(-not(Test-Path $p)){throw 'Missing Install-DDTank30Web.ps1'}
$raw=Get-Content $p -Raw
foreach($token in @('Get-DDTank30Instance.ps1','Apply-DDTank30Instance.ps1','DDTank30StaticPool','DDTank30Pool','webapps\Request','db_datareader','db_datawriter','GRANT EXECUTE','inetpub\wwwroot','Tank.Request.csproj','$requestProject','runtime-assets\v30','$runtimeWeb','gunny','Register','admingunny','legacyLoopCss','loop\.jpg','background:#ceebff','gunny\ui\vietnam\swf\core.swf','BEE0D9DB5FD6CFC827E65CFCCA01C229E3666E3B334D91F83543068DA9C65B43','Authoritative core asset hash mismatch','Canonical core asset hash mismatch after webroot copy')){if($raw -notmatch [regex]::Escape($token)){throw "Web installer missing token: $token"}}
foreach($forbidden in @("[string]`$PublicIp='103.9.156.181'",'Request.sln','RenRenAssistant','Tank.SNSAssistant')){if($raw -match [regex]::Escape($forbidden)){throw "Web installer contains forbidden legacy coupling: $forbidden"}}
Write-Host 'PASS: DDTank30 web installer consumes the single instance manifest.'