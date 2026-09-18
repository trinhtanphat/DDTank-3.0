$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rootPath = Join-Path $repo 'Game.Server\Game.Server.csproj'
$hotPath = Join-Path $repo 'Game.Server\HotSpringRooms\Game.Server.csproj'
$marryPath = Join-Path $repo 'Game.Server\SceneMarryRooms\Game.Server.csproj'

function Read-Project([string]$path) {
    [xml]$xml = Get-Content -LiteralPath $path
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace('m','http://schemas.microsoft.com/developer/msbuild/2003')
    $props = $xml.SelectSingleNode('/m:Project/m:PropertyGroup[m:ProjectGuid]', $ns)
    $compile = @($xml.SelectNodes('//m:Compile', $ns) | ForEach-Object { $_.Include })
    [pscustomobject]@{
        RootNamespace = $props.RootNamespace
        AssemblyName = $props.AssemblyName
        TargetFramework = $props.TargetFrameworkVersion
        Compile = $compile
    }
}

$root = Read-Project $rootPath
$hot = Read-Project $hotPath
$marry = Read-Project $marryPath
if ($hot.AssemblyName -ne 'Game.Server' -or $hot.TargetFramework -ne 'v3.5') { throw 'Internal HotSpringRooms snapshot is not the expected Game.Server/v3.5 lineage.' }
if (($hot.Compile -join "`n") -ne ($marry.Compile -join "`n")) { throw 'Internal Game.Server snapshots disagree on compile membership.' }
if ($root.RootNamespace -ne 'Game.Server') { throw "RootNamespace expected Game.Server, got $($root.RootNamespace)" }
if ($root.AssemblyName -ne 'Game.Server') { throw "AssemblyName expected Game.Server, got $($root.AssemblyName)" }
if ($root.TargetFramework -ne 'v3.5') { throw "TargetFramework expected v3.5, got $($root.TargetFramework)" }
if (($root.Compile -join "`n") -ne ($hot.Compile -join "`n")) { throw "Root compile graph does not match coherent internal Game.Server snapshot (root=$($root.Compile.Count), canonical=$($hot.Compile.Count))." }
Write-Host 'PASS: Game.Server root project matches coherent internal DDTank 3.0 source snapshot.'
