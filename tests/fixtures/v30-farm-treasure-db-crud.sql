SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;
DECLARE @U int=-20918001,@F int,@T int,@D int;

EXEC dbo.SP_Users_Fields_Add
 @FarmID=@U,@FieldID=0,@SeedID=332100,@PlantTime='20260918',@AccelerateTime=0,@FieldValidDate=1,
 @PayTime='21260918',@GainCount=10,@AutoSeedID=0,@AutoFertilizerID=0,@AutoSeedIDCount=0,
 @AutoFertilizerCount=0,@isAutomatic=0,@AutomaticTime='20260918',@IsExit=1,@payFieldTime=876000,@ID=@F OUTPUT;
IF @F IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Sys_User_Field WHERE ID=@F AND SeedID=332100)
    RAISERROR('field add failed',16,1);

EXEC dbo.SP_Users_Fields_Update
 @ID=@F,@FarmID=@U,@FieldID=0,@SeedID=0,@PlantTime='20260918',@AccelerateTime=0,@FieldValidDate=1,
 @PayTime='21260918',@GainCount=0,@AutoSeedID=0,@AutoFertilizerID=0,@AutoSeedIDCount=0,
 @AutoFertilizerCount=0,@isAutomatic=0,@AutomaticTime='20260918',@IsExit=1,@payFieldTime=876000;
IF NOT EXISTS(SELECT 1 FROM dbo.Sys_User_Field WHERE ID=@F AND SeedID=0)
    RAISERROR('field update failed',16,1);

EXEC dbo.SP_Users_Treasure_Add
 @ID=@T OUTPUT,@UserID=@U,@NickName=N'farm-treasure-smoke',@logoinDays=1,@treasure=1,@treasureAdd=0,
 @friendHelpTimes=0,@isEndTreasure=0,@isBeginTreasure=0,@LastLoginDay='20260918';
IF @T IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Sys_User_Treasure WHERE ID=@T)
    RAISERROR('treasure add failed',16,1);

EXEC dbo.SP_UpdateUserTreasure
 @UserID=@U,@NickName=N'farm-treasure-smoke',@logoinDays=2,@treasure=2,@treasureAdd=0,
 @friendHelpTimes=0,@isEndTreasure=0,@isBeginTreasure=1,@LastLoginDay='20260918';
IF NOT EXISTS(SELECT 1 FROM dbo.Sys_User_Treasure WHERE UserID=@U AND logoinDays=2 AND treasure=2 AND isBeginTreasure=1)
    RAISERROR('treasure update failed',16,1);

EXEC dbo.SP_TreasureData_Add
 @ID=@D OUTPUT,@UserID=@U,@TemplateID=11905,@Count=1,@Validate=0,@Pos=-1,@BeginDate='20260918',@IsExit=1;
IF @D IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Treasure_Data WHERE ID=@D AND Pos=-1)
    RAISERROR('treasure data add failed',16,1);

EXEC dbo.SP_UpdateTreasureData
 @ID=@D,@UserID=@U,@TemplateID=11905,@Count=1,@Validate=0,@Pos=1,@BeginDate='20260918',@IsExit=1;
IF NOT EXISTS(SELECT 1 FROM dbo.Treasure_Data WHERE ID=@D AND Pos=1)
    RAISERROR('treasure data update failed',16,1);

ROLLBACK TRAN;
SELECT 'DDTANK30_FARM_TREASURE_DB_CRUD=PASS' AS Result;