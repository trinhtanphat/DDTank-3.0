param(
    [string]$ServerInstance = '.\SQLEXPRESS',
    [string]$Database = 'Db_Tank_V30'
)
$ErrorActionPreference='Stop'
$sqlPath = Join-Path $PSScriptRoot 'fixtures\v30-farm-treasure-db-crud.sql'
if(-not (Test-Path $sqlPath)){ throw "Missing fixture: $sqlPath" }
& sqlcmd.exe -b -E -S $ServerInstance -d $Database -i $sqlPath
if($LASTEXITCODE -ne 0){ throw "Farm/treasure DB CRUD smoke failed: exit=$LASTEXITCODE" }
