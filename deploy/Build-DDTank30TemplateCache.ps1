param(
    [Parameter(Mandatory = $true)]
    [string]$RequestRoot,

    [string]$ExpectedDatabase = 'Db_Tank_V30',

    [int]$ExpectedMinimumCount = 3000,

    [int]$ExpectedMinimumWeaponCount = 120,

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

function Convert-XmlValue([object]$Value) {
    if ($null -eq $Value -or $Value -eq [DBNull]::Value) {
        return ''
    }
    if ($Value -is [bool]) {
        return $Value.ToString().ToLowerInvariant()
    }
    if ($Value -is [DateTime]) {
        return $Value.ToString()
    }
    if ($Value -is [IFormattable]) {
        return $Value.ToString($null, [Globalization.CultureInfo]::InvariantCulture)
    }
    return [string]$Value
}

function Read-ExistingRecycleMetadata([string]$Path, [string]$ZlibDll) {
    $metadata = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $metadata
    }

    try {
        $compressed = [IO.File]::ReadAllBytes($Path)
        $memory = New-Object IO.MemoryStream
        $stream = New-Object zlib.ZOutputStream($memory)
        try {
            $stream.Write($compressed, 0, $compressed.Length)
            $stream.Finish()
            $xmlText = [Text.Encoding]::UTF8.GetString($memory.ToArray())
        } finally {
            $stream.Close()
            $memory.Dispose()
        }

        [xml]$xml = $xmlText
        foreach ($item in @($xml.Result.ItemTemplate.Item)) {
            $id = [int]$item.TemplateID
            $metadata[$id] = [pscustomobject]@{
                CanRecycle = if ($null -ne $item.CanRecycle) { [string]$item.CanRecycle } else { '0' }
                ReclaimType = if ($null -ne $item.ReclaimType) { [string]$item.ReclaimType } else { '0' }
                ReclaimValue = if ($null -ne $item.ReclaimValue) { [string]$item.ReclaimValue } else { '0' }
            }
        }
    } catch {
        throw "Existing TemplateAlllist.xml could not be decoded safely: $($_.Exception.Message)"
    }

    return $metadata
}

$RequestRoot = [IO.Path]::GetFullPath($RequestRoot)
Require (Test-Path -LiteralPath $RequestRoot -PathType Container) "Request root not found: $RequestRoot"

$webConfig = Join-Path $RequestRoot 'Web.config'
$zlibDll = Join-Path $RequestRoot 'bin\zlib.net.dll'
Require (Test-Path -LiteralPath $webConfig -PathType Leaf) "Request Web.config not found: $webConfig"
Require (Test-Path -LiteralPath $zlibDll -PathType Leaf) "Request zlib.net.dll not found: $zlibDll"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $RequestRoot 'TemplateAlllist.xml'
}
$OutputPath = [IO.Path]::GetFullPath($OutputPath)
New-Item -ItemType Directory -Force -Path (Split-Path $OutputPath -Parent) | Out-Null

$connectionString = Get-ConfigConnectionString $webConfig
$builder = New-Object Data.SqlClient.SqlConnectionStringBuilder $connectionString
$database = [string]$builder.InitialCatalog
Require (-not [string]::IsNullOrWhiteSpace($database)) 'Request conString is missing Initial Catalog.'
if (-not [string]::IsNullOrWhiteSpace($ExpectedDatabase)) {
    Require ($database -ieq $ExpectedDatabase) "Refusing to build TemplateAlllist from unexpected database: $database"
}

$table = New-Object Data.DataTable
$connection = New-Object Data.SqlClient.SqlConnection $connectionString
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = 'dbo.SP_Items_All'
    $command.CommandType = [Data.CommandType]::StoredProcedure
    $adapter = New-Object Data.SqlClient.SqlDataAdapter $command
    [void]$adapter.Fill($table)
} finally {
    $connection.Dispose()
}

Require ($table.Rows.Count -ge $ExpectedMinimumCount) "Template item row count is unexpectedly low: $($table.Rows.Count)"

$ids = New-Object 'System.Collections.Generic.HashSet[int]'
$weaponCount = 0
foreach ($row in $table.Rows) {
    $id = [int]$row['TemplateID']
    Require ($ids.Add($id)) "Duplicate TemplateID returned by dbo.SP_Items_All: $id"
    if ([int]$row['CategoryID'] -eq 7) {
        $weaponCount++
    }
}
Require ($weaponCount -ge $ExpectedMinimumWeaponCount) "Weapon template count is unexpectedly low: $weaponCount"

Add-Type -Path $zlibDll
$existingRecycle = Read-ExistingRecycleMetadata $OutputPath $zlibDll

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
    $writer.WriteStartElement('ItemTemplate')

    foreach ($row in $table.Rows) {
        $id = [int]$row['TemplateID']
        $writer.WriteStartElement('Item')

        foreach ($name in @(
            'AddTime',
            'Agility',
            'Attack',
            'CanCompose',
            'CanDelete',
            'CanDrop',
            'CanEquip',
            'CanStrengthen',
            'CanUse',
            'CategoryID',
            'Colors',
            'Defence',
            'Description',
            'Level',
            'Luck',
            'MaxCount',
            'Name',
            'NeedLevel',
            'NeedSex',
            'Pic',
            'Data',
            'Property1',
            'Property2',
            'Property3',
            'Property4',
            'Property5',
            'Property6',
            'Property7',
            'Property8',
            'Quality',
            'Script',
            'BindType',
            'FusionType',
            'FusionRate',
            'FusionNeedRate',
            'TemplateID',
            'RefineryLevel',
            'Hole'
        )) {
            $writer.WriteAttributeString($name, (Convert-XmlValue $row[$name]))
        }

        $recycle = if ($existingRecycle.ContainsKey($id)) {
            $existingRecycle[$id]
        } else {
            [pscustomobject]@{
                CanRecycle = '0'
                ReclaimType = '0'
                ReclaimValue = '0'
            }
        }

        $writer.WriteAttributeString('CanRecycle', [string]$recycle.CanRecycle)
        $writer.WriteAttributeString('ReclaimType', [string]$recycle.ReclaimType)
        $writer.WriteAttributeString('ReclaimValue', [string]$recycle.ReclaimValue)
        $writer.WriteEndElement()
    }

    $writer.WriteEndElement()
    $writer.WriteEndElement()
    $writer.Flush()
} finally {
    $writer.Dispose()
}

$xmlText = $stringBuilder.ToString()
$xmlBytes = (New-Object Text.UTF8Encoding($false)).GetBytes($xmlText)

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

Require ($compressed.Length -gt 2) 'Compressed TemplateAlllist output is empty.'
Require ($compressed[0] -eq 0x78) 'Compressed TemplateAlllist output does not have a zlib header.'

$tempPath = $OutputPath + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
try {
    [IO.File]::WriteAllBytes($tempPath, $compressed)
    Require ((Get-Item -LiteralPath $tempPath).Length -eq $compressed.Length) 'Temporary TemplateAlllist length mismatch.'
    Move-Item -LiteralPath $tempPath -Destination $OutputPath -Force
} finally {
    if (Test-Path -LiteralPath $tempPath) {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
    }
}

$outputSha = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
Write-Host "DDTANK30_TEMPLATE_CACHE=PASS database=$database rows=$($table.Rows.Count) weapons=$weaponCount unique=$($ids.Count) preservedRecycle=$($existingRecycle.Count) sha256=$outputSha output=$OutputPath"
