param(
  [string]$ConfigPath='',
  [string]$PublicIp='',
  [int]$HttpPort=0,
  [int]$GamePort=0,
  [string]$ExternalRoot='',
  [string]$VSToolsPath='',
  [string]$ClientPatchJavaExe='',
  [string]$ClientPatchFfdecJar=''
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Get-DDTank30Instance.ps1')
$instance=Get-DDTank30Instance -ConfigPath $ConfigPath
if([string]::IsNullOrWhiteSpace($PublicIp)){$PublicIp=$instance.PublicHost}
if($HttpPort-le0){$HttpPort=$instance.WebPort}
if($GamePort-le0){$GamePort=$instance.RoadPort}
$stackRoot=$instance.Root
if([string]::IsNullOrWhiteSpace($ExternalRoot)){$ExternalRoot=Join-Path $stackRoot 'external-sources\dk-khoado-Gunny-3.0'}
if([string]::IsNullOrWhiteSpace($VSToolsPath)){$VSToolsPath=Join-Path $stackRoot 'build-prereqs\webtargets-14.0.0.3\pkg\tools\VSToolsPath'}
if([string]::IsNullOrWhiteSpace($ClientPatchJavaExe)){$ClientPatchJavaExe=Join-Path $stackRoot '_tools\jdk21\bin\java.exe'}
if([string]::IsNullOrWhiteSpace($ClientPatchFfdecJar)){$ClientPatchFfdecJar=Join-Path $stackRoot '_tools\ffdec-26.3.0\ffdec.jar'}
$repo=Join-Path $stackRoot 'repo';$webRoot=Join-Path $stackRoot 'webroot';$requestRoot=Join-Path $stackRoot 'webapps\Request'
$externalWeb=Join-Path $ExternalRoot 'inetpub\wwwroot';$msbuild='C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe'
$coreRel='gunny\ui\vietnam\swf\core.swf';$coreExpectedSha='BEE0D9DB5FD6CFC827E65CFCCA01C229E3666E3B334D91F83543068DA9C65B43';$coreSource=Join-Path $externalWeb $coreRel
$site=$instance.WebSite;$staticPool='DDTank30StaticPool';$requestPool='DDTank30Pool';$requestProject=Join-Path $repo 'Tank.Request'
foreach($p in @($externalWeb,$requestProject,(Join-Path $VSToolsPath 'WebApplications\Microsoft.WebApplication.targets'))){if(-not(Test-Path $p)){throw "Missing web prerequisite: $p"}}
if(-not(Test-Path -LiteralPath $coreSource -PathType Leaf)){throw "Authoritative core asset missing: $coreSource"}
$coreSourceHash=(Get-FileHash -LiteralPath $coreSource -Algorithm SHA256).Hash.ToUpperInvariant();if($coreSourceHash-ne$coreExpectedSha){throw "Authoritative core asset hash mismatch: $coreSourceHash"}
& $msbuild (Join-Path $requestProject 'Tank.Request.csproj') /t:Rebuild /p:Configuration=Release "/p:VSToolsPath=$VSToolsPath" /m:1 /nologo
if($LASTEXITCODE-ne0){throw "Tank.Request.csproj build failed: $LASTEXITCODE"}
New-Item -ItemType Directory -Force -Path $webRoot,$requestRoot|Out-Null
& robocopy $externalWeb $webRoot /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
if($LASTEXITCODE-gt7){throw "Static wwwroot copy failed: $LASTEXITCODE"}
$coreTarget=Join-Path $webRoot $coreRel;if(-not(Test-Path -LiteralPath $coreTarget -PathType Leaf)){throw "Canonical core asset missing after webroot copy: $coreTarget"}
$coreTargetHash=(Get-FileHash -LiteralPath $coreTarget -Algorithm SHA256).Hash.ToUpperInvariant();if($coreTargetHash-ne$coreExpectedSha){throw "Canonical core asset hash mismatch after webroot copy: $coreTargetHash"}
$runtimeWeb=Join-Path $repo 'runtime-assets\v30'
$criticalRuntimeAssets=@(
  @{Rel='gunny\2.png';Sha='A6FB0B6FD33D752E211B7F0B92ADB5B1153B15C2D7E9743E8643DE714E0D82F6'},
  @{Rel='gunny\ui\vietnam\xml\xml.png';Sha='B80EB789F02DC2ECC3B4E077DC9E4C7AB70F608806677FC75710CBE2FAB27908'}
)
if(Test-Path $runtimeWeb){
  foreach($asset in $criticalRuntimeAssets){
    $source=Join-Path $runtimeWeb $asset.Rel
    if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw "Critical runtime asset missing: $source"}
    $sha=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
    if($sha-ne$asset.Sha){throw "Critical runtime asset hash mismatch before overlay: $($asset.Rel) => $sha"}
  }
  & robocopy $runtimeWeb $webRoot /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
  if($LASTEXITCODE-gt7){throw "Runtime web asset overlay failed: $LASTEXITCODE"}
  foreach($asset in $criticalRuntimeAssets){
    $target=Join-Path $webRoot $asset.Rel
    if(-not(Test-Path -LiteralPath $target -PathType Leaf)){throw "Critical runtime asset missing after overlay: $target"}
    $sha=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant()
    if($sha-ne$asset.Sha){throw "Critical runtime asset hash mismatch after overlay: $($asset.Rel) => $sha"}
  }
}

$clientRel='gunny\2.png'
$clientInput=Join-Path $externalWeb $clientRel
$clientTarget=Join-Path $webRoot $clientRel
$clientOverlay=Join-Path $stackRoot 'client-overlays\v30\gunny\2.png'
$clientPatcher=Join-Path $PSScriptRoot 'Patch-DDTank30ClientWindAim.ps1'
$clientInputExpectedSha='7BDBF776A53913214A56D8A4A1F06B46588A36EA069E4F5B57D106549D7E2BB5'
$clientOutputExpectedSha='CFC5902ECD585669084C47D2D89ED6C56433C3458B30828A1661E6B7DCCC3F73'
foreach($p in @($clientInput,$clientPatcher)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing client wind/aim patch prerequisite: $p"}}
$clientInputSha=(Get-FileHash -LiteralPath $clientInput -Algorithm SHA256).Hash.ToUpperInvariant()
if($clientInputSha-ne$clientInputExpectedSha){throw "Authoritative client input hash mismatch: $clientInputSha"}

$clientOverlayValid=$false
if(Test-Path -LiteralPath $clientOverlay -PathType Leaf){
  $clientOverlaySha=(Get-FileHash -LiteralPath $clientOverlay -Algorithm SHA256).Hash.ToUpperInvariant()
  $clientOverlayValid=($clientOverlaySha-eq$clientOutputExpectedSha)
}
if(-not$clientOverlayValid){
  foreach($p in @($ClientPatchJavaExe,$ClientPatchFfdecJar)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing client wind/aim patch tool: $p"}}
  New-Item -ItemType Directory -Force -Path (Split-Path $clientOverlay -Parent)|Out-Null
  $clientPatchWork=Join-Path $stackRoot '_artifacts\client-wind-aim-installer'
  & $clientPatcher -InputEncodedClient $clientInput -OutputEncodedClient $clientOverlay -JavaExe $ClientPatchJavaExe -FfdecJar $ClientPatchFfdecJar -WorkRoot $clientPatchWork -ExpectedInputSha256 $clientInputExpectedSha -ExpectedOutputSha256 $clientOutputExpectedSha
  if($LASTEXITCODE-ne0){throw "Client wind/aim patcher failed: $LASTEXITCODE"}
}
Copy-Item -LiteralPath $clientOverlay -Destination $clientTarget -Force
$clientTargetHash=(Get-FileHash -LiteralPath $clientTarget -Algorithm SHA256).Hash.ToUpperInvariant()
if($clientTargetHash-ne$clientOutputExpectedSha){throw "Client wind/aim overlay hash mismatch after webroot copy: $clientTargetHash"}
$adminVipDeploy=Join-Path $PSScriptRoot 'Deploy-DDTank30AdminVip.ps1'
if(-not(Test-Path -LiteralPath $adminVipDeploy -PathType Leaf)){throw "Missing AdminGunny VIP20 deploy script: $adminVipDeploy"}
& $adminVipDeploy -RepoRoot $repo -WebRoot $webRoot -VSToolsPath $VSToolsPath

$legacyLoopCss=@(
  (Join-Path $webRoot 'gunny\scripts\style.css'),
  (Join-Path $webRoot 'gunny\scripts\index_data\style.css')
)
foreach($css in $legacyLoopCss){
  if(Test-Path -LiteralPath $css){
    $cssRaw=[IO.File]::ReadAllText($css)
    $cssFixed=$cssRaw -replace 'background:url\(\.\./images/loop\.jpg\) repeat-x #ceebff;\s*',('background:#ceebff;'+[Environment]::NewLine)
    if($cssFixed-ne$cssRaw){[IO.File]::WriteAllText($css,$cssFixed,(New-Object Text.UTF8Encoding($false)))}
  }
}
& robocopy $requestProject $requestRoot /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP /XD obj Tank.Request | Out-Null
if($LASTEXITCODE-gt7){throw "Request artifact copy failed: $LASTEXITCODE"}
try {
  & (Join-Path $PSScriptRoot 'Apply-DDTank30Instance.ps1') -ConfigPath $instance.ConfigPath -RepoRoot $repo -ApplyRuntime
} catch {
  throw "Instance config apply failed: $($_.Exception.Message)"
}
$legacyBootstrapAliases=@(
  @{Source=(Join-Path $webRoot 'gunny\Loading.swf');Target=(Join-Path $webRoot 'Loading.swf')},
  @{Source=(Join-Path $webRoot 'gunny\config.xml');Target=(Join-Path $webRoot 'config.xml')}
 )
foreach($alias in $legacyBootstrapAliases){
  if(-not(Test-Path -LiteralPath $alias.Source -PathType Leaf)){throw "Legacy bootstrap source missing: $($alias.Source)"}
  Copy-Item -LiteralPath $alias.Source -Destination $alias.Target -Force
  if((Get-FileHash -LiteralPath $alias.Source -Algorithm SHA256).Hash-ne(Get-FileHash -LiteralPath $alias.Target -Algorithm SHA256).Hash){throw "Legacy bootstrap alias hash mismatch: $($alias.Target)"}
}
Import-Module WebAdministration
foreach($pool in @($staticPool,$requestPool)){if(-not(Test-Path "IIS:\AppPools\$pool")){New-WebAppPool -Name $pool|Out-Null}}
Set-ItemProperty "IIS:\AppPools\$staticPool" -Name managedRuntimeVersion -Value ''
Set-ItemProperty "IIS:\AppPools\$staticPool" -Name managedPipelineMode -Value 'Integrated'
Set-ItemProperty "IIS:\AppPools\$requestPool" -Name managedRuntimeVersion -Value 'v4.0'
Set-ItemProperty "IIS:\AppPools\$requestPool" -Name managedPipelineMode -Value 'Integrated'
if(Test-Path "IIS:\Sites\$site"){Remove-Website -Name $site}
New-Website -Name $site -PhysicalPath $webRoot -Port $HttpPort -IPAddress $PublicIp -ApplicationPool $staticPool|Out-Null
New-WebApplication -Site $site -Name 'Request' -PhysicalPath $requestRoot -ApplicationPool $requestPool|Out-Null
foreach($app in @(@{Name='gunny';Path=(Join-Path $webRoot 'gunny')},@{Name='Register';Path=(Join-Path $webRoot 'Register')},@{Name='admingunny';Path=(Join-Path $webRoot 'admingunny')})){if(Test-Path $app.Path){New-WebApplication -Site $site -Name $app.Name -PhysicalPath $app.Path -ApplicationPool $requestPool|Out-Null}}
$iisStart=Join-Path $webRoot 'gunny\iisstart.htm'
if(Test-Path -LiteralPath $iisStart){Remove-Item -LiteralPath $iisStart -Force}
Set-WebConfigurationProperty -PSPath 'IIS:\' -Location $site -Filter 'system.webServer/directoryBrowse' -Name enabled -Value $false
$login="IIS APPPOOL\$requestPool";$c=New-Object Data.SqlClient.SqlConnection 'Data Source=.\SQLEXPRESS;Initial Catalog=master;Integrated Security=True';$c.Open()
try{
  $q=$c.CreateCommand();$q.CommandText="IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name=N'$login') CREATE LOGIN [$login] FROM WINDOWS";[void]$q.ExecuteNonQuery()
  foreach($db in @('Db_Tank_V30','Db_Count_V30','Db_Membership')){$q=$c.CreateCommand();$q.CommandText="USE [$db]; IF USER_ID(N'$login') IS NULL CREATE USER [$login] FOR LOGIN [$login]; IF IS_ROLEMEMBER(N'db_datareader',N'$login')<>1 ALTER ROLE [db_datareader] ADD MEMBER [$login]; IF IS_ROLEMEMBER(N'db_datawriter',N'$login')<>1 ALTER ROLE [db_datawriter] ADD MEMBER [$login]; GRANT EXECUTE TO [$login]; IF IS_ROLEMEMBER(N'db_owner',N'$login')=1 ALTER ROLE [db_owner] DROP MEMBER [$login];";[void]$q.ExecuteNonQuery()}
}finally{$c.Close()}
foreach($rule in @(@{Name="DDTank30 Web $HttpPort";Port=$HttpPort},@{Name="DDTank30 Game $GamePort";Port=$GamePort})){if(-not(Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue)){New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Action Allow -Protocol TCP -LocalPort $rule.Port|Out-Null}}
Start-Website -Name $site
Write-Host "DDTank30 web installed from single instance config: http://$PublicIp`:$HttpPort/ ; Request artifact=$requestRoot"
