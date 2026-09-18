$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$root=Join-Path $repo 'GameServerScript'
if(-not(Test-Path -LiteralPath $root)){throw "Missing GameServerScript root: $root"}

function Remove-CSharpStrings([string]$line) {
  return [regex]::Replace($line,'@?"(?:[^"]|"")*"|"(?:\\.|[^"\\])*"','""')
}

$violations=New-Object System.Collections.Generic.List[string]
foreach($file in Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.cs') {
  $lineNo=0
  foreach($line in Get-Content -LiteralPath $file.FullName) {
    $lineNo++
    $code=Remove-CSharpStrings $line
    if($code -match '[\(,]\s*[A-Za-z_][A-Za-z0-9_]*\s*:') {
      $violations.Add("$($file.FullName):${lineNo}: $($line.Trim())")
    }
  }
}
if($violations.Count -gt 0) {
  $sample=($violations | Select-Object -First 20) -join [Environment]::NewLine
  throw ("Legacy CodeDom-incompatible named arguments found in GameServerScript:"+[Environment]::NewLine+$sample)
}
Write-Host 'DDTANK30_LEGACY_SCRIPT_SYNTAX=PASS'