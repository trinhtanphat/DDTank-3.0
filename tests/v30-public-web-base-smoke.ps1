$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'deploy\Get-DDTank30Instance.ps1')

function Require([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw "V30_PUBLIC_WEB_BASE_SMOKE_FAIL: $Message" }
}

$example = Join-Path $root 'deploy\server-instance.example.json'
$instance = Get-DDTank30Instance -ConfigPath $example
Require ($instance.PublicWebBase -eq 'http://103.9.156.181/v30') 'publicWebBase was not parsed'
Require ($instance.PublicWebSite -eq 'Default Web Site') 'publicWebSite was not parsed'
Require ($instance.PublicWebPath -eq 'v30') 'publicWebPath was not parsed'
Require ($instance.WebPort -eq 8083) 'internal IIS webPort must remain 8083'

$apply = Get-Content (Join-Path $root 'deploy\Apply-DDTank30Instance.ps1') -Raw
Require (([regex]::Matches($apply,'\$base = \$instance\.PublicWebBase')).Count -eq 2) 'web URL writers must use PublicWebBase'
Require ($apply -match 'New-WebApplication -Site \$publicSite -Name \$publicPath') 'public root alias creation is missing'
Require ($apply -match '\$nestedName = "\$publicPath/\$\(\$app\.Name\)"') 'nested public applications are missing'
Require ($apply -match "webapps\\Request") 'public Request alias must map to webapps Request runtime'
Require ($apply -match 'DDTank30StaticPool') 'public root must use the static app pool'

Write-Host 'V30_PUBLIC_WEB_BASE_SMOKE=PASS'