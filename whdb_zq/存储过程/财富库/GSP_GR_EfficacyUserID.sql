USE ZQTreasureDB;
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go







----------------------------------------------------------------------------------------------------

-- I D 登录
ALTER PROC [dbo].[GSP_GR_EfficacyUserID]
	@dwUserID INT,								-- 用户 I D
	@strPassword NCHAR(32),						-- 用户密码
	@strClientIP NVARCHAR(15),					-- 连接地址
	@strMachineSerial NCHAR(32),				-- 机器标识
	@wKindID INT,								-- 游戏 I D
	@wServerID INT								-- 房间 I D
AS

-- 属性设置
SET NOCOUNT ON

-- 基本信息
DECLARE @UserID INT
DECLARE @FaceID INT
DECLARE @Accounts NVARCHAR(31)
DECLARE @UnderWrite NVARCHAR(63)

-- 扩展信息
DECLARE @GameID INT
DECLARE @GroupID INT
DECLARE @UserRight INT
DECLARE @Gender TINYINT
DECLARE @Loveliness INT
DECLARE @MasterRight INT
DECLARE @MasterOrder INT
DECLARE @MemberOrder INT
DECLARE @MemberOverDate DATETIME
DECLARE @GroupName NVARCHAR(31)
DECLARE @CustomFaceVer TINYINT
DECLARE @strBankPassword NCHAR(32)

-- 用户数据
DECLARE @NickName				NVARCHAR(32)						--昵称

-- 积分变量
DECLARE @Money BIGINT					--藏宝币
DECLARE @WinCount INT	
DECLARE @LostCount INT
DECLARE @DrawCount INT
DECLARE @FleeCount INT
DECLARE @Experience INT					--经验
DECLARE @Gold BIGINT					--金币
DECLARE @Gem INT						--宝石
DECLARE @Grade int						--等级
DECLARE @isAndroid						TINYINT
-- 道具信息
DECLARE @PropCount INT
-- 辅助变量
DECLARE @EnjoinLogon BIGINT
DECLARE @ErrorDescribe AS NVARCHAR(128)
DECLARE @CountNumber INT
DECLARE @Nullity BIT
DECLARE @StunDown BIT
DECLARE @LogonPass AS NCHAR(32)
DECLARE	@MachineSerial NCHAR(32)
DECLARE @MoorMachine AS TINYINT
DECLARE @OnlineTime						INT						--每天在线时长
DECLARE @Sql							NVARCHAR(1000)			--组合语句
DECLARE @Today							NVARCHAR(8)				--当天时间
DECLARE @TableName						NVARCHAR(50)			--日志表名

DECLARE @OnlineGiftCount					INT						--每天赠送次数

DECLARE @intPropID			INT						--头像道具ID
-- 执行逻辑
BEGIN

	-- 效验地址
	SELECT @EnjoinLogon=EnjoinLogon FROM ZQGameUserDB.dbo.ConfineAddress(NOLOCK) WHERE AddrString=@strClientIP AND GETDATE()<EnjoinOverDate
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SELECT [ErrorDescribe]=N'抱歉地通知您，系统禁止了您所在的 IP 地址的游戏登录权限，请联系客户服务中心了解详细情况！'
		RETURN 4
	END
	
	-- 效验机器
	SELECT @EnjoinLogon=EnjoinLogon FROM ZQGameUserDB.dbo.ConfineMachine(NOLOCK) WHERE MachineSerial=@strMachineSerial AND GETDATE()<EnjoinOverDate
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SELECT [ErrorDescribe]=N'抱歉地通知您，系统禁止了您的机器的游戏登录权限，请联系客户服务中心了解详细情况！'
		RETURN 7
	END
 
	-- 查询用户
	SELECT @UserID=UserID, @GameID=GameID, @Accounts=Accounts, @UnderWrite=UnderWrite, @LogonPass=LogonPass, @FaceID=FaceID, 
		@Gender=Gender, @Nullity=Nullity, @StunDown=StunDown, @UserRight=UserRight, @MasterRight=MasterRight,
		@MasterOrder=MasterOrder, @MemberOrder=MemberOrder,  @MemberOverDate=MemberOverDate, @MoorMachine=MoorMachine, @MachineSerial=MachineSerial, 
		@Loveliness=Loveliness,@CustomFaceVer=CustomFaceVer,@strBankPassword=InsurePass,@NickName=NickName,@isAndroid=IsAndroid,
		@Money=Money
	FROM ZQGameUserDB.dbo.AccountsInfo WHERE UserID=@dwUserID

	-- 查询用户
	IF @UserID IS NULL
	BEGIN
		SELECT [ErrorDescribe]=N'您的帐号不存在或者密码输入有误，请查证后再次尝试登录！'
		RETURN 1
	END	

	-- 帐号禁止
	IF @Nullity<>0
	BEGIN
		SELECT [ErrorDescribe]=N'您的帐号暂时处于冻结状态，请联系客户服务中心了解详细情况！'
		RETURN 2
	END	

	-- 帐号关闭
	IF @StunDown<>0
	BEGIN
		SELECT [ErrorDescribe]=N'您的帐号使用了安全关闭功能，必须到重新开通后才能继续使用！'
		RETURN 2
	END	
	
	-- 固定机器
	IF @MoorMachine=1
	BEGIN
		IF @MachineSerial<>@strMachineSerial
		BEGIN
			SELECT [ErrorDescribe]=N'您的帐号使用固定机器登录功能，您现所使用的机器不是所指定的机器！'
			RETURN 1
		END
	END

	-- 密码判断 
	IF @LogonPass<>@strPassword AND @strClientIP<>N'0.0.0.0' AND @strPassword<>N''
	BEGIN
		SELECT [ErrorDescribe]=N'您的帐号不存在或者密码输入有误，请查证后再次尝试！'
		RETURN 3
	END

	-- 固定机器
	IF @MoorMachine=2
	BEGIN
		SET @MoorMachine=1
		SELECT [ErrorDescribe]=N'您的帐号成功使用了固定机器登录功能！'
		UPDATE AccountsInfo SET MoorMachine=@MoorMachine, MachineSerial=@strMachineSerial WHERE UserID=@UserID
	END

	-- 解除锁定
	DELETE FROM GameScoreLocker WHERE UserID=@dwUserID AND KindID=@wKindID  AND ServerID=@wServerID 

	-- 房间锁定
	DECLARE @LockKindID INT
	SELECT @LockKindID=KindID FROM GameScoreLocker WHERE UserID=@dwUserID
	IF @LockKindID IS NOT NULL
	BEGIN
		DECLARE @KindName NVARCHAR(31)
		SELECT @KindName=KindName FROM ZQServerInfoDB.dbo.GameKindItem WHERE KindID=@LockKindID
		IF @KindName IS NULL SET @KindName=N'充值'
		SELECT [ErrorDescribe]=N'您已经在'+@KindName+N'游戏房间了，不能同时在进入此游戏房间了！'
		RETURN 4
	END
	INSERT GameScoreLocker (UserID,KindID,ServerID) VALUES (@dwUserID,@wKindID,@wServerID)

	-- 游戏信息
	DECLARE @GameUserRight INT
	DECLARE @GameMasterRight INT
	DECLARE @GameMasterOrder INT
	SELECT @WinCount=WinCount, @LostCount=LostCount, @DrawCount=DrawCount,
		@DrawCount=DrawCount, @FleeCount=FleeCount, @GameUserRight=UserRight, @GameMasterRight=MasterRight, 
		@GameMasterOrder=MasterOrder,@Gold=Score,@Gem=Gems,@Grade=Grade,@Experience=Experience
	FROM GameScoreInfo WHERE UserID=@dwUserID

	-- 更新信息
	UPDATE GameScoreInfo SET AllLogonTimes=AllLogonTimes+1, LastLogonDate=GETDATE(), LastLogonIP=@strClientIP WHERE UserID=@dwUserID
	
	-- 社团信息
	SET @GroupID=0
	SET @GroupName=''

	-- 权限标志
	SET @UserRight=@UserRight|@GameUserRight
	SET @MasterRight=@MasterRight|@GameMasterRight

	-- 权限等级
	IF @MasterOrder<>0 OR @GameMasterOrder<>0
	BEGIN
		IF @GameMasterOrder>@MasterOrder SET @MasterOrder=@GameMasterOrder
	END
	ELSE SET @MasterRight=0

	-- 进入记录
	-- INSERT RecordUserEnter (UserID, Score, KindID, ServerID, ClientIP) VALUES (@UserID, @Gold, @wKindID, @wServerID, @strClientIP)
	--进入房间/退出房间 时间
	IF(@dwUserID>4000)
	BEGIN
		INSERT ZQGameUserDB.dbo.UserLoginRoomLog (UserID,RoomID,LoginTime,LogoutTime) VALUES (@UserID,@wServerID,GETDATE(),GETDATE())
	END

/* 2011-09-30  删除（游戏中没有会员）
	-- 会员等级
	IF GETDATE()>=@MemberOverDate 
	BEGIN 
		SET @MemberOrder=0

		-- 删除过期会员身份
		DELETE FROM ZQGameUserDBLink.ZQGameUserDB.dbo.MemberInfo WHERE UserID=@UserID
	END
	ELSE 
	BEGIN
		DECLARE @MemberCurDate DATETIME

		-- 当前会员时间
		SELECT @MemberCurDate=MIN(MemberOverDate) 
		FROM ZQGameUserDBLink.ZQGameUserDB.dbo.MemberInfo WHERE UserID=@UserID

		-- 删除过期会员
		IF GETDATE()>=@MemberCurDate
		BEGIN
			-- 删除会员期限过期的所有会员身份
			DELETE FROM ZQGameUserDBLink.ZQGameUserDB.dbo.MemberInfo WHERE UserID=@UserID AND MemberOverDate<=GETDATE()

			-- 切换到下一级别会员身份
			SELECT @MemberOrder=MAX(MemberOrder) 
			FROM ZQGameUserDBLink.ZQGameUserDB.dbo.MemberInfo WHERE UserID=@UserID
			IF @MemberOrder IS NOT NULL
			BEGIN
				UPDATE ZQGameUserDBLink.ZQGameUserDB.dbo.AccountsInfo 
				SET MemberOrder=@MemberOrder
				WHERE UserID=@UserID
			END
			ELSE SET @MemberOrder=0
		END
	END

	-- 更新信息
	UPDATE ZQGameUserDBLink.ZQGameUserDB.dbo.AccountsInfo SET MemberOrder=@MemberOrder WHERE UserID=@UserID
*/
	-- 会员道具
	SELECT @PropCount=@PropCount+COUNT(UserID) FROM ZQGameUserDB.dbo.MemberInfo WHERE UserID=@UserID
	
	--大厅头像
	SELECT @intPropID = A.PropID FROM ZQWebDB.dbo.prop_used AS A 
	INNER JOIN ZQWebDB.dbo.prop_info AS B ON (A.PropID=B.ID) 
	WHERE A.UserID = @UserID AND A.PropID IN (SELECT FaceID FROM ZQGameUserDB.dbo.IndividualDatum WHERE UserID=@UserID)AND A.OverTime >= GETDATE()

	IF(@intPropID IS NOT NULL)--道具购买头像
	BEGIN
		SET @FaceID=@intPropID
	END
	ELSE -- 默认(男女)头像
	BEGIN
		SET @FaceID=0
	END

	-- 登录统计
	DECLARE @DateID INT
	SET @DateID=CAST(CAST(GETDATE() AS FLOAT) AS INT)
	UPDATE SystemStreamInfo SET LogonCount=LogonCount+1 WHERE DateID=@DateID AND KindID=@wKindID AND ServerID=@wServerID
	IF @@ROWCOUNT=0 INSERT SystemStreamInfo (DateID, KindID, ServerID, LogonCount) VALUES (@DateID, @wKindID, @wServerID, 1)
	
	--取当天玩家在线时长
	SET @Today=LEFT(CONVERT(NVARCHAR(20),GETDATE(),112),8)
	SET @TableName='WriteGameEndLog_'+LEFT(@Today,6)

	IF EXISTS(SELECT * FROM ZQTreasureDB.DBO.SYSOBJECTS WHERE name=@TableName)
	BEGIN
		SET @Sql='SELECT @OnlineTime=SUM(PlayTimeCount) FROM '+@TableName+' 
			WHERE UserID='+CONVERT(NVARCHAR(10),@UserID)+' AND CONVERT(NVARCHAR(20),CreateDate,112) = '+@Today
		EXEC sp_executesql @Sql, N'@OnlineTime INT OUTPUT', @OnlineTime OUTPUT
	END

	IF @OnlineTime IS NULL
		SET @OnlineTime=0

	--SELECT @OnlineGiftCount=COUNT(*) FROM UserNewGift WHERE Type=2 AND UserID=@UserID AND CONVERT(NVARCHAR(20),CreateDate,112)=CONVERT(NVARCHAR(20),GETDATE(),112)
	-------------------
	-- 输出变量
	SELECT @UserID AS UserID, @GameID AS GameID, @GroupID AS GroupID, @Accounts AS Accounts, @UnderWrite AS UnderWrite, @FaceID AS FaceID, 
		@Gender AS Gender, @GroupName AS GroupName, @MasterOrder AS MemberOrder, @UserRight AS UserRight, @MasterRight AS MasterRight, 
		@MasterOrder AS MasterOrder, @MemberOrder AS MemberOrder, @WinCount AS WinCount, @LostCount AS LostCount, @Loveliness AS Loveliness,
		@PropCount AS PropCount,@Money AS lMoney, @CustomFaceVer AS CustomFaceVer,
		@DrawCount AS DrawCount, @FleeCount AS FleeCount,@Experience AS Experience, @ErrorDescribe AS ErrorDescribe,
		@strBankPassword AS BankPassword,@Gold as lGold,@Gem as lGem,
		@Grade as dwGrade,@NickName AS NickName,@isAndroid AS IsAndroid,@OnlineTime AS OnlineTime,@OnlineGiftCount AS OnlineGiftCount
END

RETURN 0






