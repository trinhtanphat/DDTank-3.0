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
$clientPath=Join-Path $repo 'runtime-assets\v30\gunny\2.png'
$clientExpectedSha='A6FB0B6FD33D752E211B7F0B92ADB5B1153B15C2D7E9743E8643DE714E0D82F6'
$clientExpectedLength=1842968
if(-not(Test-Path -LiteralPath $clientPath -PathType Leaf)){throw "Missing canonical v30 client generation: $clientPath"}
$clientHash=(Get-FileHash -LiteralPath $clientPath -Algorithm SHA256).Hash
if($clientHash-ne$clientExpectedSha){throw "Canonical v30 client generation hash mismatch: $clientHash"}
if((Get-Item -LiteralPath $clientPath).Length-ne$clientExpectedLength){throw "Canonical v30 client generation length mismatch"}

$clientProvPath=Join-Path $repo 'runtime\client-v30-generation-20260918.json'
if(-not(Test-Path -LiteralPath $clientProvPath -PathType Leaf)){throw "Missing v30 client generation provenance: $clientProvPath"}
$clientProv=Get-Content -LiteralPath $clientProvPath -Raw | ConvertFrom-Json
if(([string]$clientProv.input_sha256).ToUpperInvariant()-ne$clientExpectedSha){throw 'v30 client provenance input SHA mismatch'}
if(([string]$clientProv.patched_output_sha256).ToUpperInvariant()-ne'67F283A0369AC790FF7EA67F7347C025A3714B17F8380A5B6112C7C0B23049CF'){throw 'v30 client provenance patched output SHA mismatch'}
if(([string]$clientProv.patched_swf_sha256).ToUpperInvariant()-ne'328FEC709C127ED4D00BABF96D949CCC2924752A279915F375AAF33F9D691B39'){throw 'v30 client provenance patched SWF SHA mismatch'}
if(([string]$clientProv.patch_contract)-ne'wind-aim-resource-host-prelogin-selfid-projectile-v5'){throw 'v30 client provenance patch contract mismatch'}
Write-Host 'PASS: DDTank30 canonical A6FB client generation is pinned for post-mirror wind patching.'
