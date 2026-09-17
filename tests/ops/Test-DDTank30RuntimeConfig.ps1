$ErrorActionPreference = 'Stop'
$runtime = 'C:\Gunny-DDTank30\runtime'
function Assert-AppSetting([string]$configPath,[string]$key,[string]$expected) {
    [xml]$xml = Get-Content -LiteralPath $configPath
    $node = $xml.configuration.appSettings.add | Where-Object { $_.key -eq $key }
    if (-not $node) { throw "Missing appSetting $key in $configPath" }
    if ([string]$node.value -ne $expected) { throw "Runtime config mismatch: $configPath $key=$($node.value), expected $expected" }
}
Assert-AppSetting (Join-Path $runtime 'center\Center.Service.exe.config') 'Port' '9302'
Assert-AppSetting (Join-Path $runtime 'fighting\Fighting.Service.exe.config') 'Port' '9308'
Assert-AppSetting (Join-Path $runtime 'game\Road.Service.exe.config') 'Port' '9300'
Assert-AppSetting (Join-Path $runtime 'game\Road.Service.exe.config') 'LoginServerPort' '9302'
Assert-AppSetting (Join-Path $runtime 'game\Road.Service.exe.config') 'FightServerPort' '9308'
Write-Host 'PASS: DDTank30 packaged runtime ports are isolated.'