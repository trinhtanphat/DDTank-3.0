param(
  [string]$BackupRoot='C:\Gunny-DDTank30\external-sources\dk-khoado-Gunny-3.0\Server\DB',
  [switch]$ReplaceExisting
)
$ErrorActionPreference='Stop'
$server='.\SQLEXPRESS';$dataRoot='C:\Gunny-DDTank30\data';$rollbackRoot=Join-Path $dataRoot 'rollback'
New-Item -ItemType Directory -Force -Path $dataRoot,$rollbackRoot|Out-Null
$expectedHashes=@{
  'Tank.bak'='716DC3137308E163F539E27CFA9D3BB34697EFBFE823C7FB18311BFEB58BFE36'
  'count.bak'='BA1ED1E4D291D64E577D1385E9905F3C31B3B0A02D5E7FF5EC5148DEFB417026'
}
function Open-Master{$c=New-Object Data.SqlClient.SqlConnection "Data Source=$server;Initial Catalog=master;Integrated Security=True;Connect Timeout=10";$c.Open();$c}
function Sql-Literal([string]$v){$v.Replace("'","''")}
function Invoke-NonQuery($c,[string]$sql){$q=$c.CreateCommand();$q.CommandTimeout=300;$q.CommandText=$sql;[void]$q.ExecuteNonQuery()}
function Db-Exists($c,[string]$name){$q=$c.CreateCommand();$q.CommandText='SELECT COUNT(*) FROM sys.databases WHERE name=@n';[void]$q.Parameters.Add('@n',[Data.SqlDbType]::NVarChar,128);$q.Parameters['@n'].Value=$name;[int]$q.ExecuteScalar()-gt0}
function Get-Count($c,[string]$db,[string]$kind){$q=$c.CreateCommand();$q.CommandText=if($kind-eq'tables'){"SELECT COUNT(*) FROM [$db].sys.tables"}else{"SELECT COUNT(*) FROM [$db].sys.procedures"};[int]$q.ExecuteScalar()}
function Test-Lineage($c,[string]$db){
  if(-not(Db-Exists $c $db)){return $false}
  if($db-eq'Db_Tank_V30'){
    if((Get-Count $c $db 'tables')-ne67 -or (Get-Count $c $db 'procs')-ne277){return $false}
    $q=$c.CreateCommand();$q.CommandText="SELECT CAST(Value AS nvarchar(100)) FROM [Db_Tank_V30].dbo.Server_Config WHERE Name=N'Edition'";return ([string]$q.ExecuteScalar()-eq'21000')
  }
  if($db-eq'Db_Count_V30'){return ((Get-Count $c $db 'tables')-eq69 -and (Get-Count $c $db 'procs')-eq201)}
  return $false
}
function Get-LogicalFiles($c,[string]$bak){
  $q=$c.CreateCommand();$q.CommandTimeout=300;$q.CommandText="RESTORE FILELISTONLY FROM DISK=N'$(Sql-Literal $bak)'";$r=$q.ExecuteReader();$d=$null;$l=$null
  try{while($r.Read()){if([string]$r['Type']-eq'D' -and -not$d){$d=[string]$r['LogicalName']};if([string]$r['Type']-eq'L' -and -not$l){$l=[string]$r['LogicalName']}}}finally{$r.Close()}
  if(-not$d -or -not$l){throw "Could not resolve logical files from $bak"};@{Data=$d;Log=$l}
}
function Assert-Source([string]$name){$p=Join-Path $BackupRoot $name;if(-not(Test-Path -LiteralPath $p)){throw "Missing authoritative backup: $p"};$h=(Get-FileHash $p -Algorithm SHA256).Hash;if($h-ne$expectedHashes[$name]){throw "SHA256 mismatch for $name"};$p}
function Backup-Existing($c,[string]$db){$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$p=Join-Path $rollbackRoot ($db+'_pre_restore_'+$stamp+'.bak');Invoke-NonQuery $c "BACKUP DATABASE [$db] TO DISK=N'$(Sql-Literal $p)' WITH COPY_ONLY, INIT, CHECKSUM";Invoke-NonQuery $c "RESTORE VERIFYONLY FROM DISK=N'$(Sql-Literal $p)' WITH CHECKSUM";Write-Host "Rollback backup verified: $p"}
function Restore-Authoritative($c,[string]$bakName,[string]$target){
  $bak=Assert-Source $bakName;Invoke-NonQuery $c "RESTORE VERIFYONLY FROM DISK=N'$(Sql-Literal $bak)'"
  if(Test-Lineage $c $target){Write-Host "$target already matches authoritative DDTank 3.0 lineage; skipping restore.";return}
  if(Db-Exists $c $target){if(-not$ReplaceExisting){throw "$target exists but does not match authoritative 3.0 lineage. Re-run with -ReplaceExisting after review."};Backup-Existing $c $target;Invoke-NonQuery $c "ALTER DATABASE [$target] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"}
  $lf=Get-LogicalFiles $c $bak;$mdf=Join-Path $dataRoot ($target+'.mdf');$ldf=Join-Path $dataRoot ($target+'_log.ldf')
  $sql="RESTORE DATABASE [$target] FROM DISK=N'$(Sql-Literal $bak)' WITH REPLACE, MOVE N'$(Sql-Literal $lf.Data)' TO N'$(Sql-Literal $mdf)', MOVE N'$(Sql-Literal $lf.Log)' TO N'$(Sql-Literal $ldf)', RECOVERY"
  try{Invoke-NonQuery $c $sql}finally{if(Db-Exists $c $target){Invoke-NonQuery $c "ALTER DATABASE [$target] SET MULTI_USER"}}
  if(-not(Test-Lineage $c $target)){throw "$target restore completed but lineage validation failed"};Write-Host "Restored and validated $target from $bakName."
}
$c=Open-Master
try{
  Restore-Authoritative $c 'Tank.bak' 'Db_Tank_V30'
  Restore-Authoritative $c 'count.bak' 'Db_Count_V30'
  if(-not(Db-Exists $c 'Db_7road_V30')){$m=Sql-Literal (Join-Path $dataRoot 'Db_7road_V30.mdf');$l=Sql-Literal (Join-Path $dataRoot 'Db_7road_V30_log.ldf');Invoke-NonQuery $c "CREATE DATABASE [Db_7road_V30] ON PRIMARY (NAME=N'Db_7road_V30',FILENAME=N'$m',SIZE=8MB,FILEGROWTH=8MB) LOG ON (NAME=N'Db_7road_V30_log',FILENAME=N'$l',SIZE=8MB,FILEGROWTH=8MB)"}
}finally{$c.Close()}
Write-Host 'DDTank30 authoritative database initialization completed.'