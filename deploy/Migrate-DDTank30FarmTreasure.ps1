param(
    [string]$ServerInstance = '.\SQLEXPRESS',
    [string]$SourceDatabase = 'Db_Tank',
    [string]$TargetDatabase = 'Db_Tank_V30'
)

$ErrorActionPreference = 'Stop'

function New-Connection([string]$database) {
    $cs = "Data Source=$ServerInstance;Initial Catalog=$database;Integrated Security=True;MultipleActiveResultSets=True"
    $cn = New-Object System.Data.SqlClient.SqlConnection $cs
    $cn.Open()
    return $cn
}

function Invoke-Sql([System.Data.SqlClient.SqlConnection]$cn, [string]$sql) {
    $cmd = $cn.CreateCommand()
    $cmd.CommandTimeout = 120
    $cmd.CommandText = $sql
    [void]$cmd.ExecuteNonQuery()
}

$master = New-Connection 'master'
try {
    $check = $master.CreateCommand()
    $check.CommandText = "SELECT CASE WHEN DB_ID(@src) IS NOT NULL AND DB_ID(@dst) IS NOT NULL THEN 1 ELSE 0 END"
    [void]$check.Parameters.AddWithValue('@src', $SourceDatabase)
    [void]$check.Parameters.AddWithValue('@dst', $TargetDatabase)
    if ([int]$check.ExecuteScalar() -ne 1) {
        throw "Source/target database missing: $SourceDatabase -> $TargetDatabase"
    }

    $target = New-Connection $TargetDatabase
    try {
        Invoke-Sql $target @"
IF OBJECT_ID('dbo.Sys_User_Field','U') IS NULL
BEGIN
    CREATE TABLE dbo.Sys_User_Field(
        ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        FarmID int NOT NULL CONSTRAINT DF_V30_Field_FarmID DEFAULT(0),
        FieldID int NOT NULL CONSTRAINT DF_V30_Field_FieldID DEFAULT(0),
        SeedID int NOT NULL CONSTRAINT DF_V30_Field_SeedID DEFAULT(0),
        PlantTime datetime NOT NULL CONSTRAINT DF_V30_Field_PlantTime DEFAULT(GETDATE()),
        AccelerateTime int NOT NULL CONSTRAINT DF_V30_Field_Accelerate DEFAULT(0),
        FieldValidDate int NOT NULL CONSTRAINT DF_V30_Field_Valid DEFAULT(1),
        PayTime datetime NOT NULL CONSTRAINT DF_V30_Field_PayTime DEFAULT(GETDATE()),
        GainCount int NOT NULL CONSTRAINT DF_V30_Field_Gain DEFAULT(0),
        AutoSeedID int NOT NULL CONSTRAINT DF_V30_Field_AutoSeed DEFAULT(0),
        AutoFertilizerID int NOT NULL CONSTRAINT DF_V30_Field_AutoFertilizer DEFAULT(0),
        AutoSeedIDCount int NOT NULL CONSTRAINT DF_V30_Field_AutoSeedCount DEFAULT(0),
        AutoFertilizerCount int NOT NULL CONSTRAINT DF_V30_Field_AutoFertilizerCount DEFAULT(0),
        isAutomatic bit NOT NULL CONSTRAINT DF_V30_Field_Automatic DEFAULT(0),
        AutomaticTime datetime NOT NULL CONSTRAINT DF_V30_Field_AutomaticTime DEFAULT(GETDATE()),
        IsExit bit NOT NULL CONSTRAINT DF_V30_Field_IsExit DEFAULT(1),
        payFieldTime int NOT NULL CONSTRAINT DF_V30_Field_PayFieldTime DEFAULT(876000)
    );
    CREATE UNIQUE INDEX UX_V30_User_Field_Farm_Field ON dbo.Sys_User_Field(FarmID,FieldID);
END;

IF OBJECT_ID('dbo.Sys_User_Treasure','U') IS NULL
BEGIN
    CREATE TABLE dbo.Sys_User_Treasure(
        ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserID int NOT NULL,
        NickName nvarchar(50) NULL,
        logoinDays int NOT NULL CONSTRAINT DF_V30_Treasure_LoginDays DEFAULT(1),
        treasure int NOT NULL CONSTRAINT DF_V30_Treasure_Count DEFAULT(1),
        treasureAdd int NOT NULL CONSTRAINT DF_V30_Treasure_Add DEFAULT(0),
        friendHelpTimes int NOT NULL CONSTRAINT DF_V30_Treasure_Help DEFAULT(0),
        isEndTreasure bit NOT NULL CONSTRAINT DF_V30_Treasure_End DEFAULT(0),
        isBeginTreasure bit NOT NULL CONSTRAINT DF_V30_Treasure_Begin DEFAULT(0),
        LastLoginDay datetime NOT NULL CONSTRAINT DF_V30_Treasure_LastLogin DEFAULT(GETDATE())
    );
    CREATE UNIQUE INDEX UX_V30_User_Treasure_UserID ON dbo.Sys_User_Treasure(UserID);
END;

IF OBJECT_ID('dbo.Treasure_Data','U') IS NULL
BEGIN
    CREATE TABLE dbo.Treasure_Data(
        ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserID int NOT NULL,
        TemplateID int NOT NULL,
        Count int NOT NULL,
        Validate int NOT NULL,
        Pos int NOT NULL CONSTRAINT DF_V30_TreasureData_Pos DEFAULT(-1),
        BeginDate datetime NOT NULL CONSTRAINT DF_V30_TreasureData_Begin DEFAULT(GETDATE()),
        IsExit bit NOT NULL CONSTRAINT DF_V30_TreasureData_IsExit DEFAULT(1)
    );
    CREATE INDEX IX_V30_Treasure_Data_UserID ON dbo.Treasure_Data(UserID,IsExit);
END;

IF OBJECT_ID('dbo.Treasure_Award','U') IS NULL
BEGIN
    CREATE TABLE dbo.Treasure_Award(
        ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        TemplateID int NOT NULL,
        Name nvarchar(250) NOT NULL,
        Count int NOT NULL,
        Validate int NOT NULL,
        Random int NOT NULL,
        strengthLevel int NOT NULL CONSTRAINT DF_V30_TreasureAward_Strength DEFAULT(0),
        isBind bit NOT NULL CONSTRAINT DF_V30_TreasureAward_Bind DEFAULT(1),
        TypeAward int NOT NULL CONSTRAINT DF_V30_TreasureAward_Type DEFAULT(0)
    );
END;
"@

        $procedures = @(
@"
CREATE PROCEDURE dbo.SP_Get_SingleFields @ID int AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.Sys_User_Field WHERE FarmID=@ID AND IsExit=1 ORDER BY FieldID;
END
"@,
@"
CREATE PROCEDURE dbo.SP_Users_Fields_Add
    @FarmID int,@FieldID int,@SeedID int,@PlantTime datetime,@AccelerateTime int,
    @FieldValidDate int,@PayTime datetime,@GainCount int,@AutoSeedID int,
    @AutoFertilizerID int,@AutoSeedIDCount int,@AutoFertilizerCount int,
    @isAutomatic bit,@AutomaticTime datetime,@IsExit bit,@payFieldTime int,@ID int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM dbo.Sys_User_Field WHERE FarmID=@FarmID AND FieldID=@FieldID)
    BEGIN
        SELECT @ID=ID FROM dbo.Sys_User_Field WHERE FarmID=@FarmID AND FieldID=@FieldID;
        RETURN 0;
    END;
    INSERT dbo.Sys_User_Field(FarmID,FieldID,SeedID,PlantTime,AccelerateTime,FieldValidDate,PayTime,GainCount,AutoSeedID,AutoFertilizerID,AutoSeedIDCount,AutoFertilizerCount,isAutomatic,AutomaticTime,IsExit,payFieldTime)
    VALUES(@FarmID,@FieldID,@SeedID,@PlantTime,@AccelerateTime,@FieldValidDate,@PayTime,@GainCount,@AutoSeedID,@AutoFertilizerID,@AutoSeedIDCount,@AutoFertilizerCount,@isAutomatic,@AutomaticTime,@IsExit,@payFieldTime);
    SET @ID=CONVERT(int,SCOPE_IDENTITY());
    RETURN 0;
END
"@,
@"
CREATE PROCEDURE dbo.SP_Users_Fields_Update
    @ID int,@FarmID int,@FieldID int,@SeedID int,@PlantTime datetime,@AccelerateTime int,
    @FieldValidDate int,@PayTime datetime,@GainCount int,@AutoSeedID int,
    @AutoFertilizerID int,@AutoSeedIDCount int,@AutoFertilizerCount int,
    @isAutomatic bit,@AutomaticTime datetime,@IsExit bit,@payFieldTime int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Sys_User_Field SET FarmID=@FarmID,FieldID=@FieldID,SeedID=@SeedID,PlantTime=@PlantTime,
        AccelerateTime=@AccelerateTime,FieldValidDate=@FieldValidDate,PayTime=@PayTime,GainCount=@GainCount,
        AutoSeedID=@AutoSeedID,AutoFertilizerID=@AutoFertilizerID,AutoSeedIDCount=@AutoSeedIDCount,
        AutoFertilizerCount=@AutoFertilizerCount,isAutomatic=@isAutomatic,AutomaticTime=@AutomaticTime,
        IsExit=@IsExit,payFieldTime=@payFieldTime
    WHERE ID=@ID;
    RETURN 0;
END
"@,
@"
CREATE PROCEDURE dbo.SP_GetSingleTreasure @UserID int AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.Sys_User_Treasure WHERE UserID=@UserID;
END
"@,
@"
CREATE PROCEDURE dbo.SP_GetSingleTreasureData @UserID int AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.Treasure_Data WHERE UserID=@UserID AND IsExit=1 ORDER BY ID;
END
"@,
@"
CREATE PROCEDURE dbo.SP_Treasure_All AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.Treasure_Award ORDER BY ID;
END
"@,
@"
CREATE PROCEDURE dbo.SP_Users_Treasure_Add
    @ID int OUTPUT,@UserID int,@NickName nvarchar(50),@logoinDays int,@treasure int,@treasureAdd int,
    @friendHelpTimes int,@isEndTreasure bit,@isBeginTreasure bit,@LastLoginDay datetime
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM dbo.Sys_User_Treasure WHERE UserID=@UserID)
    BEGIN
        SELECT @ID=ID FROM dbo.Sys_User_Treasure WHERE UserID=@UserID;
        RETURN 0;
    END;
    INSERT dbo.Sys_User_Treasure(UserID,NickName,logoinDays,treasure,treasureAdd,friendHelpTimes,isEndTreasure,isBeginTreasure,LastLoginDay)
    VALUES(@UserID,@NickName,@logoinDays,@treasure,@treasureAdd,@friendHelpTimes,@isEndTreasure,@isBeginTreasure,@LastLoginDay);
    SET @ID=CONVERT(int,SCOPE_IDENTITY());
    RETURN 0;
END
"@,
@"
CREATE PROCEDURE dbo.SP_UpdateUserTreasure
    @UserID int,@NickName nvarchar(50),@logoinDays int,@treasure int,@treasureAdd int,
    @friendHelpTimes int,@isEndTreasure bit,@isBeginTreasure bit,@LastLoginDay datetime
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Sys_User_Treasure SET NickName=@NickName,logoinDays=@logoinDays,treasure=@treasure,
        treasureAdd=@treasureAdd,friendHelpTimes=@friendHelpTimes,isEndTreasure=@isEndTreasure,
        isBeginTreasure=@isBeginTreasure,LastLoginDay=@LastLoginDay WHERE UserID=@UserID;
    RETURN 0;
END
"@,
@"
CREATE PROCEDURE dbo.SP_TreasureData_Add
    @ID int OUTPUT,@UserID int,@TemplateID int,@Count int,@Validate int,@Pos int,@BeginDate datetime,@IsExit bit
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.Treasure_Data(UserID,TemplateID,Count,Validate,Pos,BeginDate,IsExit)
    VALUES(@UserID,@TemplateID,@Count,@Validate,@Pos,@BeginDate,@IsExit);
    SET @ID=CONVERT(int,SCOPE_IDENTITY());
    RETURN 0;
END
"@,
@"
CREATE PROCEDURE dbo.SP_UpdateTreasureData
    @ID int,@UserID int,@TemplateID int,@Count int,@Validate int,@Pos int,@BeginDate datetime,@IsExit bit
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Treasure_Data SET UserID=@UserID,TemplateID=@TemplateID,Count=@Count,Validate=@Validate,
        Pos=@Pos,BeginDate=@BeginDate,IsExit=@IsExit WHERE ID=@ID;
    RETURN 0;
END
"@
        )

        $names = @(
            'SP_Get_SingleFields','SP_Users_Fields_Add','SP_Users_Fields_Update','SP_GetSingleTreasure',
            'SP_GetSingleTreasureData','SP_Treasure_All','SP_Users_Treasure_Add','SP_UpdateUserTreasure',
            'SP_TreasureData_Add','SP_UpdateTreasureData'
        )
        for($i=0;$i -lt $procedures.Count;$i++) {
            Invoke-Sql $target ("IF OBJECT_ID('dbo."+$names[$i]+"','P') IS NOT NULL DROP PROCEDURE dbo."+$names[$i])
            Invoke-Sql $target $procedures[$i]
        }
    }
    finally {
        $target.Dispose()
    }

    $cols = 'TemplateID,Name,Remark,CategoryID,Description,Attack,Defence,Agility,Luck,Level,Quality,Pic,MaxCount,NeedSex,NeedLevel,CanStrengthen,CanCompose,CanDrop,CanEquip,CanUse,CanDelete,Script,Data,Colors,Property1,Property2,Property3,Property4,Property5,Property6,Property7,Property8,Valid,Count,AddTime,BindType,FusionType,FusionRate,FusionNeedRate,Hole,RefineryLevel'
    $seedSql = @"
INSERT [$TargetDatabase].dbo.Shop_Goods($cols)
SELECT $cols
FROM [$SourceDatabase].dbo.Shop_Goods s
WHERE s.CategoryID IN (32,34)
  AND NOT EXISTS (SELECT 1 FROM [$TargetDatabase].dbo.Shop_Goods d WHERE d.TemplateID=s.TemplateID);

SET IDENTITY_INSERT [$TargetDatabase].dbo.Treasure_Award ON;
INSERT [$TargetDatabase].dbo.Treasure_Award(ID,TemplateID,Name,Count,Validate,Random,strengthLevel,isBind,TypeAward)
SELECT a.ID,a.TemplateID,a.Name,a.Count,a.Validate,a.Random,a.strengthLevel,a.isBind,a.TypeAward
FROM [$SourceDatabase].dbo.Treasure_Award a
WHERE EXISTS (SELECT 1 FROM [$TargetDatabase].dbo.Shop_Goods g WHERE g.TemplateID=a.TemplateID)
  AND NOT EXISTS (SELECT 1 FROM [$TargetDatabase].dbo.Treasure_Award d WHERE d.ID=a.ID);
SET IDENTITY_INSERT [$TargetDatabase].dbo.Treasure_Award OFF;
"@
    Invoke-Sql $master $seedSql

    $verify = $master.CreateCommand()
    $verify.CommandText = @"
SELECT
 (SELECT COUNT(*) FROM [$TargetDatabase].dbo.Shop_Goods WHERE CategoryID IN (32,34)) AS FarmTemplates,
 (SELECT COUNT(*) FROM [$TargetDatabase].dbo.Treasure_Award) AS TreasureAwards,
 (SELECT COUNT(*) FROM [$TargetDatabase].sys.procedures WHERE name IN ('SP_Get_SingleFields','SP_Users_Fields_Add','SP_Users_Fields_Update','SP_GetSingleTreasure','SP_GetSingleTreasureData','SP_Treasure_All','SP_Users_Treasure_Add','SP_UpdateUserTreasure','SP_TreasureData_Add','SP_UpdateTreasureData')) AS Procedures
"@
    $reader = $verify.ExecuteReader()
    [void]$reader.Read()
    $farmTemplates = [int]$reader['FarmTemplates']
    $treasureAwards = [int]$reader['TreasureAwards']
    $procCount = [int]$reader['Procedures']
    $reader.Close()

    if($farmTemplates -lt 10) { throw "Farm template seed incomplete: $farmTemplates" }
    if($treasureAwards -lt 16) { throw "Treasure award seed incomplete: $treasureAwards" }
    if($procCount -ne 10) { throw "Farm/treasure procedure count mismatch: $procCount/10" }

    Write-Host "DDTANK30_FARM_TREASURE_DB_MIGRATION=PASS farmTemplates=$farmTemplates treasureAwards=$treasureAwards procedures=$procCount"
}
finally {
    $master.Dispose()
}
