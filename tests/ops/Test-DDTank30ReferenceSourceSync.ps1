$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script = Join-Path $repoRoot 'deploy\Sync-DDTank30ReferenceSources.ps1'
if (-not (Test-Path -LiteralPath $script)) { throw 'Reference source sync script is missing.' }

$tokens = $null
$errors = $null
[Management.Automation.Language.Parser]::ParseFile($script,[ref]$tokens,[ref]$errors) | Out-Null
if ($errors.Count -gt 0) { throw "Reference source sync script has syntax errors: $($errors[0].Message)" }

$raw = Get-Content -LiteralPath $script -Raw
$required = @(
  '[switch]$UpdateWorkingTrees',
  'unexpected origin',
  'refusing to update dirty reference tree',
  "'fetch','origin'",
  "'merge','--ff-only'",
  'git clone --filter=blob:none',
  'Gunny92-001-code-backup',
  'geniushuai-DDTank-3.0'
)
foreach ($snippet in $required) {
  if (-not $raw.Contains($snippet)) { throw "Reference source sync safety contract missing: $snippet" }
}
Write-Host 'PASS: DDTank30 reference-source sync is syntax-valid and preserves safe fetch/fast-forward guards.'
