$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$root=Join-Path $repo 'runtime-assets\v30\gunny'
$expected=@{
  '2.png'='A6FB0B6FD33D752E211B7F0B92ADB5B1153B15C2D7E9743E8643DE714E0D82F6'
  'ui\vietnam\swf\choicefigure.swf'='0BD68ABA20EB62E4B7A97616828BC16563ABC24D1A1678C39353750B27BCD886'
  'ui\vietnam\xml\xml.png'='B80EB789F02DC2ECC3B4E077DC9E4C7AB70F608806677FC75710CBE2FAB27908'
}
foreach($rel in $expected.Keys){
  $p=Join-Path $root $rel
  if(-not(Test-Path $p)){throw "Missing runtime asset: $rel"}
  $hash=(Get-FileHash $p -Algorithm SHA256).Hash
  if($hash-ne$expected[$rel]){throw "Runtime asset hash mismatch: $rel $hash"}
}
Write-Host 'PASS: DDTank30 canonical runtime web assets (including VIP20 carrier/XML) are pinned.'