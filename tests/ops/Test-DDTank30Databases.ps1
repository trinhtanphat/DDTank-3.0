$ErrorActionPreference = 'Stop'
$server = '.\SQLEXPRESS'
$dataRoot = 'C:\Gunny-DDTank30\data'
$expected = @('Db_Tank_V30','Db_Count_V30','Db_7road_V30')
$legacy = @('Db_Tank','Db_Count')
$failures = New-Object System.Collections.Generic.List[string]

function Open-Master {
    $c = New-Object System.Data.SqlClient.SqlConnection "Data Source=$server;Initial Catalog=master;Integrated Security=True;Connect Timeout=5"
    $c.Open()
    return $c
}

function Get-DbState($connection, [string]$name) {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = 'SELECT state_desc FROM sys.databases WHERE name=@name'
    [void]$cmd.Parameters.Add('@name',[System.Data.SqlDbType]::NVarChar,128)
    $cmd.Parameters['@name'].Value = $name
    $value = $cmd.ExecuteScalar()
    if ($null -eq $value -or $value -is [DBNull]) { return $null }
    return [string]$value
}

function Get-DbFiles($connection, [string]$name) {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = 'SELECT physical_name FROM sys.master_files WHERE database_id=DB_ID(@name) ORDER BY file_id'
    [void]$cmd.Parameters.Add('@name',[System.Data.SqlDbType]::NVarChar,128)
    $cmd.Parameters['@name'].Value = $name
    $items = @()
    $r = $cmd.ExecuteReader()
    try { while ($r.Read()) { $items += [string]$r.GetValue(0) } }
    finally { $r.Close() }
    return $items
}

$c = Open-Master
try {
    foreach ($name in $expected) {
        $state = Get-DbState $c $name
        if ($null -eq $state) {
            $failures.Add("Missing database $name")
            continue
        }
        if ($state -ne 'ONLINE') { $failures.Add("$name state is $state, expected ONLINE") }
        $files = @(Get-DbFiles $c $name)
        if ($files.Count -eq 0) { $failures.Add("$name has no database files") }
        foreach ($file in $files) {
            if (-not $file.StartsWith($dataRoot,[System.StringComparison]::OrdinalIgnoreCase)) {
                $failures.Add("$name file is outside isolated data root: $file")
            }
        }
    }

    foreach ($name in $legacy) {
        $state = Get-DbState $c $name
        if ($state -ne 'ONLINE') { $failures.Add("Legacy database $name must remain ONLINE; state=$state") }
    }
    $legacyFiles = @()
    foreach ($name in $legacy) { $legacyFiles += @(Get-DbFiles $c $name) }
    foreach ($name in $expected) {
        foreach ($file in @(Get-DbFiles $c $name)) {
            if ($legacyFiles -contains $file) { $failures.Add("$name shares legacy database file: $file") }
        }
    }
}
finally { $c.Close() }

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "DDTank30 database isolation failed with $($failures.Count) error(s)."
}
Write-Host 'PASS: DDTank30 databases are isolated and legacy databases remain online.'
