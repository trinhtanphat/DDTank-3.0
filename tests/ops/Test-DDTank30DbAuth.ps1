$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$configs = @(
  'Center.Service\App.config','Fighting.Service\App.config','Game.Service\App.config',
  'GameAdmin\Web.config','Road.Request\Web.config','Tank.Request\Web.config','Tank.Request\Tank.Request\Web.config'
)
$checked = 0
foreach ($relative in $configs) {
  $path = Join-Path $repo $relative
  [xml]$xml = Get-Content -LiteralPath $path
  $entries = @()
  $entries += @($xml.configuration.appSettings.add | ForEach-Object { [pscustomobject]@{Name=$_.key; Value=$_.value} })
  $entries += @($xml.configuration.connectionStrings.add | ForEach-Object { [pscustomobject]@{Name=$_.name; Value=$_.connectionString} })
  foreach ($entry in $entries) {
    $value = [string]$entry.Value
    if ($value -notmatch '(?i)Initial\s+Catalog\s*=\s*Db_[^;]*_V30') { continue }
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder $value
    $checked++
    if (-not $builder.IntegratedSecurity) { throw "$relative $($entry.Name) must use Integrated Security." }
    if ($builder.UserID -or $builder.Password) { throw "$relative $($entry.Name) must not embed SQL credentials." }
  }
}
if ($checked -lt 10) { throw "Expected at least 10 V30 connections, checked $checked." }
Write-Host "PASS: $checked V30 connection strings use Windows authentication with no embedded SQL credentials."