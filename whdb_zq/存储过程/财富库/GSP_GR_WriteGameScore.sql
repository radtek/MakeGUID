USE ZQTreasureDB;
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go






----------------------------------------------------------------------------------------------------

-- 游戏写分
ALTER PROC [dbo].[GSP_GR_WriteGameScore]
	@dwUserID						INT,							-- 用户 I D
	@lWinCount						INT,							-- 胜利盘数
	@lLostCount						INT,							-- 失败盘数
	@lDrawCount						INT,							-- 和局盘数
	@lFleeCount						INT,							-- 断线数目
	@lExperience					INT,							-- 用户经验
	@wKindID						INT,							-- 游戏 I D
	@wServerID						INT,							-- 房间 I D
	@strClientIP					NVARCHAR(15),					-- 连接地址
	@lGold							INT,							-- 金币
	@lGem							INT,							-- 宝石
	@dwGrade						INT,							-- 等级
	@lRevenue						INT,							-- 游戏税收
	@dwPlayTimeCount				INT								-- 游戏时间
AS

DECLARE @currMonth	NVARCHAR(40)				--当前年月份
DECLARE @CreeentGold		INT					--金币 
DECLARE @LastGold			INT					--变动后金币

-- 执行逻辑	 
BEGIN
	--用户变动之前宝石
	SELECT @CreeentGold=Score FROM GameScoreInfo WHERE UserID=@dwUserID
	-- 用户积分
	UPDATE GameScoreInfo SET Score=Score+@lGold, WinCount=WinCount+@lWinCount, LostCount=LostCount+@lLostCount,
		DrawCount=DrawCount+@lDrawCount, FleeCount=FleeCount+@lFleeCount,Experience=Experience+@lExperience,Grade=Grade+@dwGrade,Gems=Gems+@lGem
	WHERE UserID=@dwUserID
	--变动后金币
	SET @LastGold=(@CreeentGold+(@lGold))
	--结算日志
	SELECT @currMonth='WriteGameEndLog_'+LEFT(CONVERT(NVARCHAR(8),GETDATE(),112),6)
	IF NOT EXISTS(SELECT * FROM ZQTreasureDB.DBO.SYSOBJECTS WHERE name=@currMonth)
	BEGIN
		EXEC ('CREATE TABLE '+@currMonth+'(
				[id] [bigint] IDENTITY(1,1) NOT NULL,
				[UserID] [int] NOT NULL,
				[KindID] [int] NOT NULL,
				[ServerID] [int] NOT NULL,
				[WinCount] [tinyint] NOT NULL DEFAULT ((0)),
				[LostCount] [tinyint] NOT NULL DEFAULT ((0)),
				[DrawCount] [tinyint] NOT NULL DEFAULT ((0)),
				[FleeCount] [tinyint] NOT NULL DEFAULT ((0)),
				[Revenue] [int] NOT NULL DEFAULT ((0)),
				[PlayTimeCount] [int] NOT NULL DEFAULT ((0)),
				[Experience] [int] NOT NULL DEFAULT ((0)),
				[Gold] [int] NOT NULL DEFAULT ((0)),
				[Grade] [tinyint] NOT NULL DEFAULT ((0)),
				[CurrentGold] [int] NOT NULL DEFAULT ((0)),
				[LastGold] [int] NOT NULL DEFAULT ((0)),
				[ClientIP] [varchar](15),
				[CreateDate] [datetime] NULL DEFAULT (getdate()),
				CONSTRAINT [PK_'+@currMonth+'] PRIMARY KEY CLUSTERED 
				(
					[id] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
			) ON [PRIMARY]
		')
	END
	--新增结算日志
	EXEC ('INSERT INTO '+@currMonth+'(UserID,KindID,ServerID,WinCount,LostCount,DrawCount,FleeCount,Revenue,PlayTimeCount,Experience,
		Gold,Grade,CurrentGold,LastGold,ClientIP) VALUES
		('+@dwUserID+','+@wKindID+','+@wServerID+','+@lWinCount+','+@lLostCount+','+@lDrawCount+','+@lFleeCount+','+@lRevenue+','+@dwPlayTimeCount+','+@lExperience+','+
		@lGold+','+@dwGrade+','+@CreeentGold+','+@LastGold+','''+@strClientIP+''')')
	--金币变动
	/*SET @currMonth='ZQWebDB.dbo.UserGoldLog_'+LEFT(CONVERT(NVARCHAR(8),GETDATE(),112),6)
	EXEC ('INSERT INTO '+@currMonth+'(UserID,ChangeType,LastGold,ChangeGold,IpAddress) VALUES
		('+@dwUserID+',1,'+@LastGold+','+@lGold+','''+@strClientIP+''')')*/

	--金币变动日志
	DECLARE @CTableNameDate				NVARCHAR(6)
	SET @CTableNameDate=LEFT(CONVERT(NVARCHAR(8),GETDATE(),112),6)

	DECLARE @CSql NVARCHAR(1000)
	SET @CSql='ZQTreasureDB.dbo.GSP_GP_IN_WriteGoldLog
		@CTableNameDate = '+@CTableNameDate+',
		@IUserID = '+CONVERT(NVARCHAR(10),@dwUserID)+',
		@TChangeType = 1,
		@IChangeGold = '+CONVERT(NVARCHAR(10),@lGold)+',
		@CIpAddress = '''+CONVERT(NVARCHAR(15),@strClientIP)+''''
	EXEC (@CSql)
END




