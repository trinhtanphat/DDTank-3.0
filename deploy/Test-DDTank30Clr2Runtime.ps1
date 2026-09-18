param(
    [string]$RuntimeRoot = 'C:\Gunny-DDTank30\runtime'
)

$ErrorActionPreference = 'Stop'
$runtime = [IO.Path]::GetFullPath($RuntimeRoot)
$gameLogic = Join-Path $runtime 'game\Game.Logic.dll'
$fightLogic = Join-Path $runtime 'fighting\Game.Logic.dll'

foreach ($path in @($gameLogic, $fightLogic)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing CLR2 runtime dependency: $path"
    }
}

$gameHash = (Get-FileHash -LiteralPath $gameLogic -Algorithm SHA256).Hash
$fightHash = (Get-FileHash -LiteralPath $fightLogic -Algorithm SHA256).Hash
if ($gameHash -ne $fightHash) {
    throw "Game.Logic drift between game/fighting runtime: game=$gameHash fighting=$fightHash"
}

$assembly = [Reflection.Assembly]::ReflectionOnlyLoadFrom($gameLogic)
if ($assembly.ImageRuntimeVersion -ne 'v2.0.50727') {
    throw "Game.Logic targets unexpected CLR image runtime: $($assembly.ImageRuntimeVersion)"
}

$refs = @($assembly.GetReferencedAssemblies())
$forbidden = @($refs | Where-Object {
    $_.Name -in @('mscorlib', 'System.Drawing') -and $_.Version.Major -ge 4
})
if ($forbidden.Count -gt 0) {
    $names = ($forbidden | ForEach-Object { $_.FullName }) -join '; '
    throw "CLR4 reference leaked into CLR2 Game.Logic: $names"
}

foreach ($required in @(
    @{ Name = 'mscorlib'; Major = 2 },
    @{ Name = 'System.Drawing'; Major = 2 }
)) {
    $hit = @($refs | Where-Object {
        $_.Name -eq $required.Name -and $_.Version.Major -eq $required.Major
    })
    if ($hit.Count -eq 0) {
        throw "Missing expected CLR2 reference: $($required.Name) $($required.Major).x"
    }
}

Write-Host "DDTANK30_CLR2_RUNTIME_GUARD=PASS sha256=$gameHash"
