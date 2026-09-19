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
if(Test-Path $runtimeWeb){
  & robocopy $runtimeWeb $webRoot /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
  if($LASTEXITCODE-gt7){throw "Runtime web asset overlay failed: $LASTEXITCODE"}
}

$legacyConfig=Join-Path $webRoot 'gunny\config.xml'
if(Test-Path -LiteralPath $legacyConfig -PathType Leaf){
  [xml]$legacyXml=[IO.File]::ReadAllText($legacyConfig,[Text.Encoding]::UTF8)
  $legacyNode=$legacyXml.root.config
  if($legacyNode.STATISTIC){$legacyNode.STATISTIC.SetAttribute('value','false')}
  if($legacyNode.COUNT_PATH){$legacyNode.COUNT_PATH.SetAttribute('value','')}
  if($legacyNode.PHP){
    $legacyNode.PHP.SetAttribute('isShow','false')
    $legacyNode.PHP.SetAttribute('link','false')
    $legacyNode.PHP.SetAttribute('site','')
    $legacyNode.PHP.SetAttribute('infoPath','')
  }
  if($legacyNode.COMMUNITY_FRIEND_PATH){
    $legacyNode.COMMUNITY_FRIEND_PATH.SetAttribute('isUser','false')
    $legacyNode.COMMUNITY_FRIEND_PATH.SetAttribute('value','')
  }
  if($legacyNode.COMMUNITY_INVITE_PATH){$legacyNode.COMMUNITY_INVITE_PATH.SetAttribute('value','')}
  if($legacyNode.COMMUNITY_FRIEND_LIST_PATH){
    $legacyNode.COMMUNITY_FRIEND_LIST_PATH.SetAttribute('value','')
    $legacyNode.COMMUNITY_FRIEND_LIST_PATH.SetAttribute('snsPath','')
    $legacyNode.COMMUNITY_FRIEND_LIST_PATH.SetAttribute('isexist','false')
    $legacyNode.COMMUNITY_FRIEND_LIST_PATH.SetAttribute('isexistBtnVisble','false')
    $legacyNode.COMMUNITY_FRIEND_LIST_PATH.SetAttribute('cmBtnVisble','false')
  }
  if($legacyNode.COMMUNITY_INTERFACE){
    $legacyNode.COMMUNITY_INTERFACE.SetAttribute('enable','false')
    $legacyNode.COMMUNITY_INTERFACE.SetAttribute('path','')
    $legacyNode.COMMUNITY_INTERFACE.SetAttribute('shareBtnVisble','false')
  }
  if($legacyNode.EXTERNAL_INTERFACE){
    $legacyNode.EXTERNAL_INTERFACE.SetAttribute('enable','false')
    $legacyNode.EXTERNAL_INTERFACE.SetAttribute('path','')
  }
  $legacyXmlSettings=New-Object Xml.XmlWriterSettings
  $legacyXmlSettings.Encoding=New-Object Text.UTF8Encoding($false)
  $legacyXmlSettings.Indent=$true
  $legacyXmlWriter=[Xml.XmlWriter]::Create($legacyConfig,$legacyXmlSettings)
  try{$legacyXml.Save($legacyXmlWriter)}finally{$legacyXmlWriter.Dispose()}
}

$clientRel='gunny\2.png'
$clientTarget=Join-Path $webRoot $clientRel
$clientInput=$clientTarget
$clientPatcher=Join-Path $PSScriptRoot 'Patch-DDTank30ClientWindAim.ps1'
$clientResourceBaseUrl=('http://'+$PublicIp+':'+$HttpPort+'/Resource/')
$clientPatchContract='wind-aim-resource-host-prelogin-selfid-v4'
foreach($p in @($clientInput,$clientPatcher)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing client wind/aim patch prerequisite: $p"}}

$clientInputSha=(Get-FileHash -LiteralPath $clientInput -Algorithm SHA256).Hash.ToUpperInvariant()
$clientGenerationRoot=Join-Path $stackRoot ('client-overlays\v30\'+$clientInputSha)
$clientOverlay=Join-Path $clientGenerationRoot 'gunny\2.png'
$clientManifest=Join-Path $clientGenerationRoot 'manifest.json'
$clientSourceStore=Join-Path $stackRoot ('client-sources\v30\'+$clientInputSha+'\gunny\2.png')

New-Item -ItemType Directory -Force -Path (Split-Path $clientSourceStore -Parent)|Out-Null
if(-not(Test-Path -LiteralPath $clientSourceStore -PathType Leaf)){
  Copy-Item -LiteralPath $clientInput -Destination $clientSourceStore -Force
}
$clientSourceStoreSha=(Get-FileHash -LiteralPath $clientSourceStore -Algorithm SHA256).Hash.ToUpperInvariant()
if($clientSourceStoreSha-ne$clientInputSha){throw "Stored client source hash mismatch: $clientSourceStoreSha"}

$clientOverlayValid=$false
$clientPatchedSha=''
if((Test-Path -LiteralPath $clientOverlay -PathType Leaf) -and (Test-Path -LiteralPath $clientManifest -PathType Leaf)){
  try{
    $clientMeta=Get-Content -LiteralPath $clientManifest -Raw | ConvertFrom-Json
    $manifestInputSha=([string]$clientMeta.input_sha256).ToUpperInvariant()
    $manifestOutputSha=([string]$clientMeta.output_sha256).ToUpperInvariant()
    $manifestPatchContract=[string]$clientMeta.patch_contract
    $manifestResourceBaseUrl=[string]$clientMeta.resource_base_url
    if($manifestInputSha-eq$clientInputSha -and $manifestOutputSha -and $manifestPatchContract-eq$clientPatchContract -and $manifestResourceBaseUrl-eq$clientResourceBaseUrl){
      $clientOverlaySha=(Get-FileHash -LiteralPath $clientOverlay -Algorithm SHA256).Hash.ToUpperInvariant()
      if($clientOverlaySha-eq$manifestOutputSha){
        $clientPatchedSha=$manifestOutputSha
        $clientOverlayValid=$true
      }
    }
  }catch{
    $clientOverlayValid=$false
  }
}

if(-not$clientOverlayValid){
  foreach($p in @($ClientPatchJavaExe,$ClientPatchFfdecJar)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing client wind/aim patch tool: $p"}}
  New-Item -ItemType Directory -Force -Path (Split-Path $clientOverlay -Parent)|Out-Null

  $clientPatchId=[Guid]::NewGuid().ToString('N')
  $clientPatchWork=Join-Path $stackRoot ('_artifacts\client-wind-aim-installer\'+$clientInputSha+'-'+$clientPatchId)
  $clientOverlayTemp=Join-Path $clientGenerationRoot ('2.'+$clientPatchId+'.tmp.png')
  try{
    & $clientPatcher -InputEncodedClient $clientInput -OutputEncodedClient $clientOverlayTemp -JavaExe $ClientPatchJavaExe -FfdecJar $ClientPatchFfdecJar -WorkRoot $clientPatchWork -ExpectedInputSha256 $clientInputSha -ResourceBaseUrl $clientResourceBaseUrl
    if($LASTEXITCODE-ne0){throw "Client wind/aim patcher failed: $LASTEXITCODE"}

    $clientPatchedSha=(Get-FileHash -LiteralPath $clientOverlayTemp -Algorithm SHA256).Hash.ToUpperInvariant()
    if(-not$clientPatchedSha -or $clientPatchedSha-eq$clientInputSha){throw "Client wind/aim patcher produced an invalid output hash: $clientPatchedSha"}

    Move-Item -LiteralPath $clientOverlayTemp -Destination $clientOverlay -Force
    $clientOverlaySha=(Get-FileHash -LiteralPath $clientOverlay -Algorithm SHA256).Hash.ToUpperInvariant()
    if($clientOverlaySha-ne$clientPatchedSha){throw "Client generation overlay hash mismatch: $clientOverlaySha"}

    $clientMeta=[ordered]@{
      input_sha256=$clientInputSha
      output_sha256=$clientPatchedSha
      generated_at=(Get-Date).ToString('o')
      patcher='Patch-DDTank30ClientWindAim.ps1'
      patch_contract=$clientPatchContract
      resource_base_url=$clientResourceBaseUrl
    }
    $clientManifestTemp=$clientManifest+'.tmp'
    $clientMeta | ConvertTo-Json | Set-Content -LiteralPath $clientManifestTemp -Encoding UTF8
    Move-Item -LiteralPath $clientManifestTemp -Destination $clientManifest -Force
  }finally{
    if(Test-Path -LiteralPath $clientOverlayTemp){Remove-Item -LiteralPath $clientOverlayTemp -Force -ErrorAction SilentlyContinue}
    if(Test-Path -LiteralPath $clientPatchWork){Remove-Item -LiteralPath $clientPatchWork -Recurse -Force -ErrorAction SilentlyContinue}
  }
}

Copy-Item -LiteralPath $clientOverlay -Destination $clientTarget -Force
$clientTargetHash=(Get-FileHash -LiteralPath $clientTarget -Algorithm SHA256).Hash.ToUpperInvariant()
if($clientTargetHash-ne$clientPatchedSha){throw "Client wind/aim overlay hash mismatch after webroot copy: $clientTargetHash"}
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
$ballListBuilder=Join-Path $PSScriptRoot 'Build-DDTank30BallListCache.ps1'
if(-not(Test-Path -LiteralPath $ballListBuilder -PathType Leaf)){throw "Missing BallList cache builder: $ballListBuilder"}
& $ballListBuilder -RequestRoot $requestRoot -ExpectedDatabase 'Db_Tank_V30' -ExpectedMinimumCount 300
$ballListPath=Join-Path $requestRoot 'BallList.xml'
if(-not(Test-Path -LiteralPath $ballListPath -PathType Leaf)){throw "BallList cache missing after rebuild: $ballListPath"}
$templateCacheBuilder=Join-Path $PSScriptRoot 'Build-DDTank30TemplateCache.ps1'
if(-not(Test-Path -LiteralPath $templateCacheBuilder -PathType Leaf)){throw "Missing item template cache builder: $templateCacheBuilder"}
& $templateCacheBuilder -RequestRoot $requestRoot -ExpectedDatabase 'Db_Tank_V30' -ExpectedMinimumCount 3000 -ExpectedMinimumWeaponCount 120
$templateCachePath=Join-Path $requestRoot 'TemplateAlllist.xml'
if(-not(Test-Path -LiteralPath $templateCachePath -PathType Leaf)){throw "TemplateAlllist cache missing after rebuild: $templateCachePath"}
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
