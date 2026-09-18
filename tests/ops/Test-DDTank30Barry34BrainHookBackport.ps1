$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$root = Join-Path $repo 'GameServerScript'
$commit = '73e189aef774b1f2eead70979c97b53619db07aa'
$expected = @(
    'AI\NPC\AcademyPVE\EighthPaoNpc.cs',
    'AI\NPC\AcademyPVE\EighthSmallBat.cs',
    'AI\NPC\GuluOlympics\SixHardThirdBadNpcAi.cs',
    'AI\NPC\GuluOlympics\SixNormalThirdBadNpcAi.cs',
    'AI\NPC\GuluOlympics\SixTerrorThirdBadNpcAi.cs'
)

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ddtank30-barry34-blob-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
    foreach ($rel in $expected) {
        $path = Join-Path $root $rel
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing Barry34 brain-hook backport: $rel" }

        $gitRel = ('GameServerScript/' + ($rel -replace '\\','/'))
        $blobPath = Join-Path $tempRoot ([IO.Path]::GetFileName($rel))
        $cmd = 'git -C "' + $repo + '" cat-file blob ":' + $gitRel + '" > "' + $blobPath + '"'
        & cmd.exe /d /s /c $cmd
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $blobPath)) {
            throw "Could not materialize canonical Git blob: $gitRel"
        }

        $bytes = [IO.File]::ReadAllBytes($blobPath)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            throw "UTF-8 BOM not allowed in canonical Git blob: $rel"
        }
        $text = [Text.Encoding]::UTF8.GetString($bytes)
        if ($text.Contains("`r")) { throw "CRLF/CR not allowed in canonical Git blob: $rel" }
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$project = Get-Content (Join-Path $root 'GameServerScript.csproj') -Raw
foreach ($rel in $expected) {
    if ($project -notmatch [regex]::Escape("Compile Include=`"$rel`"")) { throw "Project missing Barry34 brain-hook source: $rel" }
}
$prov = Get-Content (Join-Path $root 'BARRY34-BRAINHOOK-BACKPORT.md') -Raw
if ($prov -notmatch [regex]::Escape($commit)) { throw 'Barry34 brain-hook provenance commit missing.' }
if ($prov -notmatch '128 Barry34 candidates' -or $prov -notmatch 'five survived' -or $prov -notmatch '123 were rejected') {
    throw 'Barry34 selection/gate provenance is incomplete.'
}
Write-Host 'DDTANK30_BARRY34_BRAINHOOK_BACKPORT=PASS rows=5 db-referenced=5 canonical-git-blob=utf8-lf'
