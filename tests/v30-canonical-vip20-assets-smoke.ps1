$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Require([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw "V30_CANONICAL_VIP20_ASSETS_FAIL: $Message" }
}

$expected2 = 'A6FB0B6FD33D752E211B7F0B92ADB5B1153B15C2D7E9743E8643DE714E0D82F6'
$expectedXml = 'B80EB789F02DC2ECC3B4E077DC9E4C7AB70F608806677FC75710CBE2FAB27908'
$asset2 = Join-Path $root 'runtime-assets\v30\gunny\2.png'
$assetXml = Join-Path $root 'runtime-assets\v30\gunny\ui\vietnam\xml\xml.png'
$install = Get-Content (Join-Path $root 'deploy\Install-DDTank30Web.ps1') -Raw
$apply = Get-Content (Join-Path $root 'deploy\Apply-DDTank30Instance.ps1') -Raw

Require (Test-Path $asset2) 'canonical VIP20 carrier is missing'
Require (Test-Path $assetXml) 'canonical VIP20 XML is missing'
Require ((Get-FileHash $asset2 -Algorithm SHA256).Hash -eq $expected2) 'canonical VIP20 carrier hash mismatch'
Require ((Get-FileHash $assetXml -Algorithm SHA256).Hash -eq $expectedXml) 'canonical VIP20 XML hash mismatch'

Require ($install.Contains($expected2)) 'installer does not pin VIP20 carrier hash'
Require ($install.Contains($expectedXml)) 'installer does not pin VIP20 XML hash'
Require ($install -match 'Critical runtime asset hash mismatch before overlay') 'pre-overlay hash gate is missing'
Require ($install -match 'Critical runtime asset hash mismatch after overlay') 'post-overlay hash gate is missing'

Require ($apply -match "gunny\\Loading\.swf") 'Apply-DDTank30Instance must keep legacy Loading.swf alias synchronized'
Require ($apply -match 'Target=\(Join-Path \$WebRoot ''config\.xml''\)') 'Apply-DDTank30Instance must keep root config.xml synchronized'

Write-Host 'V30_CANONICAL_VIP20_ASSETS=PASS'