$ErrorActionPreference='Stop'
$expectedIp='103.9.156.181'; $expectedPort='9300'
[xml]$x=Get-Content 'C:\Gunny-DDTank30\repo\Game.Service\App.config' -Raw
$apps=@($x.configuration.appSettings.add)
$ip=[string](@($apps|Where-Object{$_.key-eq'IP'})[0].value)
$port=[string](@($apps|Where-Object{$_.key-eq'Port'})[0].value)
if($ip-ne$expectedIp-or$port-ne$expectedPort){throw "Source Game endpoint mismatch: $ip`:$port"}
$cn=New-Object System.Data.SqlClient.SqlConnection 'Data Source=.\SQLEXPRESS;Initial Catalog=Db_Tank_V30;Integrated Security=True';$cn.Open()
$cmd=$cn.CreateCommand();$cmd.CommandText='SELECT TOP 1 IP+''|''+CAST(Port AS varchar(10)) FROM Server_List WHERE ID=4';$v=[string]$cmd.ExecuteScalar();$cn.Close()
if($v-ne($expectedIp+'|'+$expectedPort)){throw "Db_Tank_V30 Server_List mismatch: $v"}
Write-Host 'PASS: DDTank30 public game endpoint is isolated on 103.9.156.181:9300.'
