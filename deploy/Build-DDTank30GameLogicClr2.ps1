param(
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = Join-Path $repo 'Game.Logic\Game.Logic.csproj'

$msbuildCommand = Get-Command msbuild.exe -ErrorAction SilentlyContinue
if ($msbuildCommand) {
    $msbuild = $msbuildCommand.Source
}
else {
    $msbuild = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe'
}
if (-not (Test-Path -LiteralPath $msbuild)) {
    throw "MSBuild v4 was not found: $msbuild"
}

# The repository historically tracked build outputs and stale FileListAbsolute files
# containing absolute paths from other machines. Do not use Rebuild/Clean here:
# explicitly remove only the Game.Logic compiler outputs we own, then build.
$binDir = Join-Path $repo "Game.Logic\bin\$Configuration"
$objDir = Join-Path $repo "Game.Logic\obj\$Configuration"
$ownedOutputs = @(
    (Join-Path $binDir 'Game.Logic.dll'),
    (Join-Path $binDir 'Game.Logic.pdb'),
    (Join-Path $objDir 'Game.Logic.dll'),
    (Join-Path $objDir 'Game.Logic.pdb')
)
foreach ($output in $ownedOutputs) {
    Remove-Item -LiteralPath $output -Force -ErrorAction SilentlyContinue
}
$buildStarted = Get-Date

& $msbuild $project /t:Build "/p:Configuration=$Configuration" /p:TargetFrameworkVersion=v3.5 /p:BuildProjectReferences=false /m:1 /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) {
    throw "Game.Logic CLR2 build failed with exit $LASTEXITCODE"
}

$dll = Join-Path $binDir 'Game.Logic.dll'
if (-not (Test-Path -LiteralPath $dll)) {
    throw "Game.Logic build output missing: $dll"
}
if ((Get-Item -LiteralPath $dll).LastWriteTime -lt $buildStarted.AddSeconds(-2)) {
    throw "Game.Logic build output is stale: $dll"
}

$assembly = [Reflection.Assembly]::ReflectionOnlyLoadFrom($dll)
if ($assembly.ImageRuntimeVersion -ne 'v2.0.50727') {
    throw "Game.Logic targets unexpected CLR image runtime: $($assembly.ImageRuntimeVersion)"
}

$refs = @($assembly.GetReferencedAssemblies())
$forbidden = @($refs | Where-Object {
    $_.Name -in @('mscorlib', 'System.Drawing') -and $_.Version.Major -ge 4
})
if ($forbidden.Count -gt 0) {
    $names = ($forbidden | ForEach-Object { $_.FullName }) -join '; '
    throw "CLR4 reference leaked into source-built Game.Logic: $names"
}

foreach ($required in @(
    @{ Name = 'mscorlib'; Major = 2 },
    @{ Name = 'System.Drawing'; Major = 2 }
)) {
    if (@($refs | Where-Object {
        $_.Name -eq $required.Name -and $_.Version.Major -eq $required.Major
    }).Count -eq 0) {
        throw "Missing expected CLR2 reference: $($required.Name) $($required.Major).x"
    }
}

$hash = (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash
Write-Host "DDTANK30_GAMELOGIC_CLR2_BUILD=PASS sha256=$hash"
