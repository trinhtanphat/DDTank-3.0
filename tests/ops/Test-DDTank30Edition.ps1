$ErrorActionPreference = 'Stop'
$c = New-Object System.Data.SqlClient.SqlConnection 'Data Source=.\SQLEXPRESS;Initial Catalog=Db_Tank_V30;Integrated Security=True;Connect Timeout=5'
$c.Open()
try {
  $cmd=$c.CreateCommand(); $cmd.CommandText="SELECT COUNT(*) FROM dbo.Server_Config WHERE Name=N'Edition'"; $count=[int]$cmd.ExecuteScalar()
  if($count -ne 1){ throw "Expected exactly one Edition row in Db_Tank_V30, found $count." }
  $cmd=$c.CreateCommand(); $cmd.CommandText="SELECT CAST(Value AS nvarchar(100)) FROM dbo.Server_Config WHERE Name=N'Edition'"; $value=[string]$cmd.ExecuteScalar()
  if($value -ne '21000'){ throw "Db_Tank_V30 Edition=$value, expected 21000." }
} finally { $c.Close() }
Write-Host 'PASS: Db_Tank_V30 Edition matches DDTank30 source gate (21000).'
