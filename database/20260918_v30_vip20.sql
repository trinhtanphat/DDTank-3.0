/*
  DDTank/Gunny 3.0 VIP20 compatibility migration.
  Run against the 3.0 game database (Db_Tank_V30).
  The legacy server previously sent fake VIP5/50000 data on every login.
*/
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.Sys_VIP_Info','U') IS NULL
BEGIN
    CREATE TABLE dbo.Sys_VIP_Info
    (
        UserID int NOT NULL PRIMARY KEY,
        typeVIP int NOT NULL CONSTRAINT DF_V30_VIP_type DEFAULT(0),
        VIPLevel int NOT NULL CONSTRAINT DF_V30_VIP_level DEFAULT(1),
        VIPExp int NOT NULL CONSTRAINT DF_V30_VIP_exp DEFAULT(0),
        VIPOnlineDays int NOT NULL CONSTRAINT DF_V30_VIP_online DEFAULT(0),
        VIPOfflineDays int NOT NULL CONSTRAINT DF_V30_VIP_offline DEFAULT(0),
        VIPExpireDay datetime NOT NULL CONSTRAINT DF_V30_VIP_expire DEFAULT(GETDATE()),
        LastVIPPackTime datetime NOT NULL CONSTRAINT DF_V30_VIP_pack DEFAULT(GETDATE()),
        VIPLastdate datetime NOT NULL CONSTRAINT DF_V30_VIP_last DEFAULT(GETDATE()),
        VIPNextLevelDaysNeeded int NOT NULL CONSTRAINT DF_V30_VIP_next DEFAULT(0),
        CanTakeVipReward bit NOT NULL CONSTRAINT DF_V30_VIP_reward DEFAULT(0)
    );
END;

IF OBJECT_ID('dbo.Server_Config','U') IS NOT NULL
BEGIN
    DECLARE @VipConfig TABLE
    (
        Name nvarchar(50) NOT NULL PRIMARY KEY,
        Value nvarchar(2000) NOT NULL
    );

    INSERT @VipConfig(Name,Value)
    VALUES
        ('VIPMaxLevel','20'),
        ('VIPExpForEachLv','0|200|400|800|2000|4000|8000|20000|40000|80000|200000|400000|800000|1200000|1800000|2600000|3600000|4800000|6200000|7800000'),
        ('VIPExpNeededForEachLv','0|200|400|800|2000|4000|8000|20000|40000|80000|200000|400000|800000|1200000|1800000|2600000|3600000|4800000|6200000|7800000'),
        ('VIPExpGainPerDay','10'),
        ('VIPExpDecreasePerDay','5');

    UPDATE target
    SET target.Value = source.Value
    FROM dbo.Server_Config AS target
    INNER JOIN @VipConfig AS source ON source.Name = target.Name;

    IF COLUMNPROPERTY(OBJECT_ID('dbo.Server_Config'),'ID','IsIdentity') = 1
    BEGIN
        INSERT dbo.Server_Config(Name,Value)
        SELECT source.Name,source.Value
        FROM @VipConfig AS source
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Server_Config AS target WHERE target.Name=source.Name);
    END
    ELSE
    BEGIN
        DECLARE @MaxConfigId int;
        SELECT @MaxConfigId=ISNULL(MAX(ID),0)
        FROM dbo.Server_Config WITH (UPDLOCK,HOLDLOCK);

        INSERT dbo.Server_Config(ID,Name,Value)
        SELECT @MaxConfigId + ROW_NUMBER() OVER (ORDER BY source.Name),
               source.Name,
               source.Value
        FROM @VipConfig AS source
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Server_Config AS target WHERE target.Name=source.Name);
    END
END;

UPDATE dbo.Sys_VIP_Info
SET VIPLevel = CASE WHEN VIPLevel < 1 THEN 1 WHEN VIPLevel > 20 THEN 20 ELSE VIPLevel END;

UPDATE dbo.Sys_VIP_Info
SET VIPExp = CASE
    WHEN VIPLevel=1  AND VIPExp < 0       THEN 0
    WHEN VIPLevel=2  AND VIPExp < 200     THEN 200
    WHEN VIPLevel=3  AND VIPExp < 400     THEN 400
    WHEN VIPLevel=4  AND VIPExp < 800     THEN 800
    WHEN VIPLevel=5  AND VIPExp < 2000    THEN 2000
    WHEN VIPLevel=6  AND VIPExp < 4000    THEN 4000
    WHEN VIPLevel=7  AND VIPExp < 8000    THEN 8000
    WHEN VIPLevel=8  AND VIPExp < 20000   THEN 20000
    WHEN VIPLevel=9  AND VIPExp < 40000   THEN 40000
    WHEN VIPLevel=10 AND VIPExp < 80000   THEN 80000
    WHEN VIPLevel=11 AND VIPExp < 200000  THEN 200000
    WHEN VIPLevel=12 AND VIPExp < 400000  THEN 400000
    WHEN VIPLevel=13 AND VIPExp < 800000  THEN 800000
    WHEN VIPLevel=14 AND VIPExp < 1200000 THEN 1200000
    WHEN VIPLevel=15 AND VIPExp < 1800000 THEN 1800000
    WHEN VIPLevel=16 AND VIPExp < 2600000 THEN 2600000
    WHEN VIPLevel=17 AND VIPExp < 3600000 THEN 3600000
    WHEN VIPLevel=18 AND VIPExp < 4800000 THEN 4800000
    WHEN VIPLevel=19 AND VIPExp < 6200000 THEN 6200000
    WHEN VIPLevel=20 AND VIPExp < 7800000 THEN 7800000
    ELSE VIPExp END;

COMMIT TRANSACTION;
GO

CREATE OR ALTER PROCEDURE dbo.SP_VIPRenewal_Single
    @UserID int,
    @RenewalDays int,
    @ExpireDayOut datetime OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @RenewalDays <= 0 OR @RenewalDays > 744 RETURN -2;
    IF NOT EXISTS (SELECT 1 FROM dbo.Sys_Users_Detail WHERE UserID=@UserID AND IsExist=1) RETURN -1;

    DECLARE @Now datetime=GETDATE();
    DECLARE @CurrentExpire datetime;

    BEGIN TRANSACTION;
    SELECT @CurrentExpire=VIPExpireDay
    FROM dbo.Sys_VIP_Info WITH (UPDLOCK,HOLDLOCK)
    WHERE UserID=@UserID;

    SET @ExpireDayOut=DATEADD(day,@RenewalDays,
        CASE WHEN @CurrentExpire IS NOT NULL AND @CurrentExpire>@Now THEN @CurrentExpire ELSE @Now END);

    IF @CurrentExpire IS NULL
    BEGIN
        INSERT dbo.Sys_VIP_Info
            (UserID,typeVIP,VIPLevel,VIPExp,VIPOnlineDays,VIPOfflineDays,VIPExpireDay,
             LastVIPPackTime,VIPLastdate,VIPNextLevelDaysNeeded,CanTakeVipReward)
        VALUES(@UserID,1,1,0,0,0,@ExpireDayOut,@Now,@Now,20,1);
    END
    ELSE
    BEGIN
        UPDATE dbo.Sys_VIP_Info
        SET typeVIP=CASE WHEN typeVIP<1 THEN 1 ELSE typeVIP END,
            VIPExpireDay=@ExpireDayOut,
            VIPLastdate=@Now,
            CanTakeVipReward=1
        WHERE UserID=@UserID;
    END

    COMMIT TRANSACTION;
    RETURN 1;
END
GO
