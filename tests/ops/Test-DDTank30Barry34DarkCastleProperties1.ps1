$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$root = Join-Path $repo 'GameServerScript'
$commit = '73e189aef774b1f2eead70979c97b53619db07aa'
$expected = @(
    'AI\NPC\DarkCastle\FourHardCycLoneNpc.cs',
    'AI\NPC\DarkCastle\FourHardFireNpc.cs',
    'AI\NPC\DarkCastle\FourNormalCycLoneNpc.cs',
    'AI\NPC\DarkCastle\FourNormalFireNpc.cs',
    'AI\NPC\DarkCastle\FourTerrorCycLoneNpc.cs',
    'AI\NPC\DarkCastle\FourTerrorFireNpc.cs'
)
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ddtank30-darkcastle-properties1-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
    foreach ($rel in $expected) {
        $path = Join-Path $root $rel
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing DarkCastle Properties1 backport: $rel" }
        $gitRel = 'GameServerScript/' + ($rel -replace '\\','/')
        $blobPath = Join-Path $tempRoot ([IO.Path]::GetFileName($rel))
        $cmd = 'git -C "' + $repo + '" cat-file blob ":' + $gitRel + '" > "' + $blobPath + '"'
        & cmd.exe /d /s /c $cmd
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $blobPath)) { throw "Could not materialize canonical Git blob: $gitRel" }
        $bytes = [IO.File]::ReadAllBytes($blobPath)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { throw "UTF-8 BOM not allowed: $rel" }
        $text = [Text.Encoding]::UTF8.GetString($bytes)
        if ($text.Contains("`r")) { throw "CRLF/CR not allowed in canonical Git blob: $rel" }
        if ($text -notmatch 'Body\.Properties1\s*=\s*0\s*;') { throw "Expected original Properties1 initialization missing: $rel" }
        if ([regex]::IsMatch($text, '[,(]\s*[A-Za-z_][A-Za-z0-9_]*\s*:')) { throw "C# 4 named arguments are not allowed: $rel" }
        if ($text -match '\$"' -or $text -match '\?\.') { throw "Modern C# syntax is not allowed: $rel" }
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
$project = Get-Content (Join-Path $root 'GameServerScript.csproj') -Raw
foreach ($rel in $expected) {
    if ($project -notmatch [regex]::Escape("Compile Include=`"$rel`"")) { throw "GameServerScript.csproj missing: $rel" }
}
$provPath = Join-Path $root 'BARRY34-DARKCASTLE-PROPERTIES1-BACKPORT.md'
if (-not (Test-Path -LiteralPath $provPath)) { throw 'DarkCastle Properties1 provenance missing.' }
$prov = Get-Content $provPath -Raw
if ($prov -notmatch [regex]::Escape($commit)) { throw 'DarkCastle Properties1 source commit missing.' }
foreach ($id in @(4102,4107,4202,4207,4302,4307)) {
    if ($prov -notmatch ("NPC ID " + $id)) { throw "DarkCastle DB NPC ID missing from provenance: $id" }
}
Write-Host 'DDTANK30_BARRY34_DARKCASTLE_PROPERTIES1=PASS rows=6 db-referenced=6 runtime-csharp3-safe=true'
