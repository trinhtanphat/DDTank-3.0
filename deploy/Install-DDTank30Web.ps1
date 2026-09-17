param(
  [string]$ConfigPath='',
  [string]$PublicIp='',
  [int]$HttpPort=0,
  [int]$GamePort=0,
  [string]$ExternalRoot='',
  [string]$VSToolsPath=''
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
& (Join-Path $PSScriptRoot 'Apply-DDTank30Instance.ps1') -ConfigPath $instance.ConfigPath -RepoRoot $repo -ApplyRuntime
if($LASTEXITCODE-ne0){throw "Instance config apply failed: $LASTEXITCODE"}
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