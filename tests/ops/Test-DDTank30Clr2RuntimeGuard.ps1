$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Assert-Contains([string]$relativePath, [string[]]$needles) {
    $path = Join-Path $repo $relativePath
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing contract file: $relativePath" }
    $text = Get-Content -LiteralPath $path -Raw
    foreach ($needle in $needles) {
        if ($text -notmatch [regex]::Escape($needle)) {
            throw "Missing CLR2 guard contract in ${relativePath}: $needle"
        }
    }
}

Assert-Contains 'deploy\Test-DDTank30Clr2Runtime.ps1' @(
    'CLR4 reference leaked into CLR2 Game.Logic',
    'System.Drawing',
    'mscorlib',
    'DDTANK30_CLR2_RUNTIME_GUARD=PASS'
)
Assert-Contains 'deploy\Start-DDTank30Supervisor.ps1' @(
    'Test-DDTank30Clr2Runtime.ps1',
    '-RuntimeRoot $RuntimeRoot'
)
Assert-Contains 'tests\ops\Test-DDTank30Package.ps1' @(
    'Test-DDTank30Clr2Runtime.ps1',
    '-RuntimeRoot $runtime'
)
Assert-Contains '.github\workflows\ddtank30-contract.yml' @(
    'Validate CLR2 runtime references',
    'deploy/Test-DDTank30Clr2Runtime.ps1'
)

Write-Host 'DDTANK30_CLR2_RUNTIME_GUARD_CONTRACT=PASS'
