param(
  [string]$StackRoot = 'C:\Gunny-DDTank30',
  [switch]$UpdateWorkingTrees
)
$ErrorActionPreference = 'Stop'

$sources = @(
  @{ Name='Gunny92-001-code-backup'; Url='https://github.com/trinhtanphat/Gunny92-001-code-backup.git'; Rel='sources\Gunny92-001-code-backup'; Branch='main' },
  @{ Name='Thisorp-gunny3.0'; Url='https://github.com/Thisorp/gunny3.0.git'; Rel='sources\Thisorp-gunny3.0'; Branch='master' },
  @{ Name='dk-khoado-Gunny-3.0'; Url='https://github.com/dk-khoado/Gunny-3.0.git'; Rel='external-sources\dk-khoado-Gunny-3.0'; Branch='main' },
  @{ Name='BaseGunnyII'; Url='https://github.com/trinhtanphat/BaseGunnyII.git'; Rel='external-sources\BaseGunnyII-ip181-20260917'; Branch='master' },
  @{ Name='geniushuai-DDTank-3.0'; Url='https://github.com/geniushuai/DDTank-3.0.git'; Rel='external-sources\geniushuai-DDTank-3.0'; Branch='master' }
)

function Invoke-Git {
  param([string]$RepoPath, [string[]]$GitArgs)
  & git -C $RepoPath @GitArgs | Out-Host
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    throw "git $($GitArgs -join ' ') failed in $RepoPath"
  }
}

$results = foreach ($s in $sources) {
  $dst = Join-Path $StackRoot $s.Rel
  New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
  if (-not (Test-Path (Join-Path $dst '.git'))) {
    & git clone --filter=blob:none --single-branch --branch $s.Branch $s.Url $dst
    if ($LASTEXITCODE -ne 0) { throw "clone failed: $($s.Name)" }
  } else {
    $origin = (& git -C $dst remote get-url origin).Trim()
    if ($origin -ne $s.Url) { throw "unexpected origin for $($s.Name): $origin" }
    Invoke-Git $dst @('fetch','origin',$s.Branch,'--prune')
  }

  $dirty = @(& git -C $dst status --porcelain)
  if ($UpdateWorkingTrees) {
    if ($dirty.Count -gt 0) { throw "refusing to update dirty reference tree: $dst" }
    $branch = (& git -C $dst branch --show-current).Trim()
    if ($branch -ne $s.Branch) { Invoke-Git $dst @('checkout',$s.Branch) }
    Invoke-Git $dst @('merge','--ff-only',"origin/$($s.Branch)")
  }

  $head = (& git -C $dst rev-parse HEAD).Trim()
  $remoteHead = (& git -C $dst rev-parse "origin/$($s.Branch)").Trim()
  [pscustomobject]@{
    Name = $s.Name
    Path = $dst
    Branch = $s.Branch
    Head = $head
    RemoteHead = $remoteHead
    Dirty = ($dirty.Count -gt 0)
    InSync = ($head -eq $remoteHead)
  }
}
$results | Format-Table -AutoSize
$notInSync = @($results | Where-Object { -not $_.InSync })
if ($notInSync.Count -gt 0 -and $UpdateWorkingTrees) {
  throw 'one or more reference sources did not reach their remote branch head'
}
