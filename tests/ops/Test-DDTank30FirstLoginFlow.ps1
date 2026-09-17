$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
foreach($rel in @('Tank.Request\Login.ashx.cs','Tank.Request\Tank.Request\Login.ashx.cs')){
  $login=Get-Content (Join-Path $repo $rel) -Raw
  if($login -match 'GetUserLoginList\(name\)'){throw "$rel still blocks first-login on a pre-existing-user check."}
  if($login -match 'player\.Password\s*!=\s*pwd'){throw "$rel still rejects the activation password transition."}
  if($login -notmatch 'inter\.CreateLogin\(name, newPwd'){throw "$rel no longer delegates first-login activation to BaseInterface.CreateLogin."}
  if($login -notmatch 'PvePermission.*== null'){throw "$rel does not tolerate null PVE permission for newly activated users."}
}
foreach($rel in @('Tank.Request\VisualizeRegister.ashx.cs','Tank.Request\Tank.Request\VisualizeRegister.ashx.cs')){
  $raw=Get-Content (Join-Path $repo $rel) -Raw
  foreach($token in @('bool.TryParse(rawSex','int.TryParse(rawSex','string.IsNullOrEmpty(armID)','string.IsNullOrEmpty(hairID)','string.IsNullOrEmpty(faceID)','string.IsNullOrEmpty(ClothID)')){
    if($raw -notmatch [regex]::Escape($token)){throw "$rel missing Ruffle registration compatibility token: $token"}
  }
}
$installer=Get-Content (Join-Path $repo 'deploy\Install-DDTank30Web.ps1') -Raw
foreach($token in @('$iisStart','Remove-Item -LiteralPath $iisStart','Db_Membership')){
  if($installer -notmatch [regex]::Escape($token)){throw "Web installer missing first-login/default-document token: $token"}
}
$apply=Get-Content (Join-Path $repo 'deploy\Apply-DDTank30Instance.ps1') -Raw
foreach($token in @('Set-NamedConnectionStringIfPresent','Db_MembershipConnectionString','Db_TankConnectionString','Db_Tank_V30','Db_Membership')){
  if($apply -notmatch [regex]::Escape($token)){throw "Instance apply missing isolated registration DB token: $token"}
}
Write-Host 'PASS: DDTank30 first-login, Ruffle registration, IIS placeholder removal, and isolated registration DB contracts are pinned.'
