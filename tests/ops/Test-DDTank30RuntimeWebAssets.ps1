$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$root=Join-Path $repo 'runtime-assets\v30\gunny\ui\vietnam'
$expected=@{
  'swf\choicefigure.swf'='0BD68ABA20EB62E4B7A97616828BC16563ABC24D1A1678C39353750B27BCD886'
  'xml\xml.png'='CF444DFADBE6BC2044786A67BA16393F3907F72C3431F90450F388FD924CF366'
}
foreach($rel in $expected.Keys){
  $p=Join-Path $root $rel
  if(-not(Test-Path $p)){throw "Missing runtime asset: $rel"}
  $hash=(Get-FileHash $p -Algorithm SHA256).Hash
  if($hash-ne$expected[$rel]){throw "Runtime asset hash mismatch: $rel $hash"}
}
Write-Host 'PASS: DDTank30 10-percent choicefigure runtime assets are pinned.'
