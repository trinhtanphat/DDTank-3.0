$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$tcpFiles=@('Bussiness\app.config','Center.Service\App.config','Game.Service\App.config','GameAdmin\Web.config','Tank.Request\Tank.Request\Web.config','Tank.Request\Web.config','WebApplication1\Web.config')
foreach($rel in $tcpFiles){
  $text=Get-Content -LiteralPath (Join-Path $repo $rel) -Raw
  if($text -notmatch 'net\.tcp://127\.0\.0\.1:2309/'){throw "$rel must use isolated CenterService net.tcp port 2309."}
  if($text -match 'net\.tcp://127\.0\.0\.1:2009/'){throw "$rel still uses legacy CenterService net.tcp port 2009."}
}
$center=Get-Content -LiteralPath (Join-Path $repo 'Center.Service\App.config') -Raw
if($center -notmatch 'http://127\.0\.0\.1:2308/CenterService/'){throw 'Center.Service App.config must use isolated HTTP metadata port 2308.'}
if($center -match 'http://127\.0\.0\.1:2008/CenterService/'){throw 'Center.Service App.config still uses legacy HTTP metadata port 2008.'}
Write-Host 'PASS: DDTank30 CenterService WCF endpoints are isolated on 2308/2309.'
