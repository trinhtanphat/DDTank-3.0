$ErrorActionPreference='Stop'
$p=Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'deploy\Install-DDTank30Web.ps1'
if(-not(Test-Path $p)){throw 'Missing Install-DDTank30Web.ps1'}
$raw=Get-Content $p -Raw
foreach($token in @('DDTank30StaticPool','DDTank30Pool','103.9.156.181','8083','9300','webapps\Request','db_datareader','db_datawriter','GRANT EXECUTE','inetpub\wwwroot','Tank.Request.csproj','$requestProject')){if($raw -notmatch [regex]::Escape($token)){throw "Web installer missing token: $token"}}
foreach($forbidden in @('Request.sln','RenRenAssistant','Tank.SNSAssistant')){if($raw -match [regex]::Escape($forbidden)){throw "Web installer must not depend on solution-only project: $forbidden"}}
Write-Host 'PASS: DDTank30 web installer builds the deployable Request project directly.'