param([string]$TaskName='DDTank30-Stack')
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$supervisor=Join-Path $repo 'deploy\Start-DDTank30Supervisor.ps1'
if(-not(Test-Path $supervisor)){throw 'Supervisor script missing.'}
$cn=New-Object System.Data.SqlClient.SqlConnection 'Data Source=.\SQLEXPRESS;Initial Catalog=master;Integrated Security=True'
$cn.Open()
$cmd=$cn.CreateCommand();$cmd.CommandTimeout=60
$cmd.CommandText=@"
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name=N'NT AUTHORITY\SYSTEM') CREATE LOGIN [NT AUTHORITY\SYSTEM] FROM WINDOWS;
USE [Db_Tank_V30]; IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'NT AUTHORITY\SYSTEM') CREATE USER [NT AUTHORITY\SYSTEM] FOR LOGIN [NT AUTHORITY\SYSTEM]; IF IS_ROLEMEMBER('db_owner',N'NT AUTHORITY\SYSTEM') <> 1 ALTER ROLE [db_owner] ADD MEMBER [NT AUTHORITY\SYSTEM];
USE [Db_Count_V30]; IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'NT AUTHORITY\SYSTEM') CREATE USER [NT AUTHORITY\SYSTEM] FOR LOGIN [NT AUTHORITY\SYSTEM]; IF IS_ROLEMEMBER('db_owner',N'NT AUTHORITY\SYSTEM') <> 1 ALTER ROLE [db_owner] ADD MEMBER [NT AUTHORITY\SYSTEM];
"@
[void]$cmd.ExecuteNonQuery();$cn.Close()
$action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$supervisor+'"')
$trigger=New-ScheduledTaskTrigger -AtStartup
$principal=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew -RestartCount 99 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "PASS: installed $TaskName for isolated DDTank30 runtime."
