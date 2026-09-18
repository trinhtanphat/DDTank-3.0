param(
    [Parameter(Mandatory = $true)]
    [string]$RequestRoot,

    [string]$ExpectedDatabase = 'Db_Tank_V30',

    [int]$ExpectedMinimumCount = 300,

    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'

function Require([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw $Message
    }
}

function Get-ConfigConnectionString([string]$WebConfigPath) {
    [xml]$config = Get-Content -LiteralPath $WebConfigPath -Raw
    $entry = @($config.configuration.appSettings.add | Where-Object { $_.key -eq 'conString' }) | Select-Object -First 1
    Require ($null -ne $entry) 'Request Web.config is missing appSettings/conString.'
    $value = [string]$entry.value
    Require (-not [string]::IsNullOrWhiteSpace($value)) 'Request Web.config conString is empty.'
    return $value
}

function Convert-Invariant([object]$Value) {
    if ($null -eq $Value -or $Value -eq [DBNull]::Value) {
        return ''
    }
    if ($Value -is [bool]) {
        return $Value.ToString().ToLowerInvariant()
    }
    if ($Value -is [IFormattable]) {
        return $Value.ToString($null, [Globalization.CultureInfo]::InvariantCulture)
    }
    return [string]$Value
}

$RequestRoot = [IO.Path]::GetFullPath($RequestRoot)
Require (Test-Path -LiteralPath $RequestRoot -PathType Container) "Request root not found: $RequestRoot"

$webConfig = Join-Path $RequestRoot 'Web.config'
$zlibDll = Join-Path $RequestRoot 'bin\zlib.net.dll'
Require (Test-Path -LiteralPath $webConfig -PathType Leaf) "Request Web.config not found: $webConfig"
Require (Test-Path -LiteralPath $zlibDll -PathType Leaf) "Request zlib.net.dll not found: $zlibDll"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $RequestRoot 'BallList.xml'
}
$OutputPath = [IO.Path]::GetFullPath($OutputPath)
New-Item -ItemType Directory -Force -Path (Split-Path $OutputPath -Parent) | Out-Null

$connectionString = Get-ConfigConnectionString $webConfig
$builder = New-Object Data.SqlClient.SqlConnectionStringBuilder $connectionString
$database = [string]$builder.InitialCatalog
Require (-not [string]::IsNullOrWhiteSpace($database)) 'Request conString is missing Initial Catalog.'
if (-not [string]::IsNullOrWhiteSpace($ExpectedDatabase)) {
    Require ($database -ieq $ExpectedDatabase) "Refusing to build BallList from unexpected database: $database"
}

$table = New-Object Data.DataTable
$connection = New-Object Data.SqlClient.SqlConnection $connectionString
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = 'dbo.SP_Ball_All'
    $command.CommandType = [Data.CommandType]::StoredProcedure
    $adapter = New-Object Data.SqlClient.SqlDataAdapter $command
    [void]$adapter.Fill($table)
} finally {
    $connection.Dispose()
}

Require ($table.Rows.Count -ge $ExpectedMinimumCount) "BallList row count is unexpectedly low: $($table.Rows.Count)"

$ids = New-Object 'System.Collections.Generic.HashSet[int]'
foreach ($row in $table.Rows) {
    $id = [int]$row['ID']
    Require ($ids.Add($id)) "Duplicate Ball ID returned by dbo.SP_Ball_All: $id"
}

$settings = New-Object Xml.XmlWriterSettings
$settings.OmitXmlDeclaration = $true
$settings.Indent = $true
$settings.IndentChars = '  '
$settings.NewLineChars = [Environment]::NewLine
$settings.NewLineHandling = [Xml.NewLineHandling]::Replace
$settings.Encoding = New-Object Text.UTF8Encoding($false)

$stringBuilder = New-Object Text.StringBuilder
$writer = [Xml.XmlWriter]::Create($stringBuilder, $settings)
try {
    $writer.WriteStartElement('Result')
    $writer.WriteAttributeString('value', 'true')
    $writer.WriteAttributeString('message', 'Success!')

    foreach ($row in $table.Rows) {
        $writer.WriteStartElement('Item')
        foreach ($name in @(
            'ID',
            'Power',
            'Radii',
            'FlyingPartical',
            'BombPartical',
            'IsSpin',
            'SpinV',
            'SpinVA',
            'Amount',
            'Wind',
            'DragIndex',
            'Weight',
            'Shake',
            'ShootSound',
            'BombSound',
            'ActionType',
            'Mass'
        )) {
            $writer.WriteAttributeString($name, (Convert-Invariant $row[$name]))
        }
        $writer.WriteEndElement()
    }

    $writer.WriteEndElement()
    $writer.Flush()
} finally {
    $writer.Dispose()
}

$xmlText = $stringBuilder.ToString()
$xmlBytes = (New-Object Text.UTF8Encoding($false)).GetBytes($xmlText)

Add-Type -Path $zlibDll
$memory = New-Object IO.MemoryStream
$zstream = New-Object zlib.ZOutputStream($memory, 9)
try {
    $zstream.Write($xmlBytes, 0, $xmlBytes.Length)
    $zstream.Finish()
    $compressed = $memory.ToArray()
} finally {
    $zstream.Close()
    $memory.Dispose()
}

Require ($compressed.Length -gt 2) 'Compressed BallList output is empty.'
Require ($compressed[0] -eq 0x78) 'Compressed BallList output does not have a zlib header.'

$tempPath = $OutputPath + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
try {
    [IO.File]::WriteAllBytes($tempPath, $compressed)
    Require ((Get-Item -LiteralPath $tempPath).Length -eq $compressed.Length) 'Temporary BallList length mismatch.'
    Move-Item -LiteralPath $tempPath -Destination $OutputPath -Force
} finally {
    if (Test-Path -LiteralPath $tempPath) {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
    }
}

$outputSha = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
Write-Host "DDTANK30_BALLLIST_CACHE=PASS database=$database rows=$($table.Rows.Count) unique=$($ids.Count) sha256=$outputSha output=$OutputPath"
