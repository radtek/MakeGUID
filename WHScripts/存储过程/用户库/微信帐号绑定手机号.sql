USE WHGameUserDB
GO

IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[dbo].[GSP_GP_ModifyPhone]') and OBJECTPROPERTY(ID, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[GSP_GP_ModifyPhone]
GO

SET QUOTED_IDENTIFIER ON 
GO

SET ANSI_NULLS ON 
GO



----------------------------------------------------------------------------------------------------
-- 微信帐号绑定手机号
CREATE PROC [dbo].[GSP_GP_ModifyPhone]
	@UserId INT,						-- 用户ID
	@strPhone NVARCHAR(31)				-- 用户手机号
  AS

-- 属性设置
SET NOCOUNT ON

-- 扩展信息
-- 辅助变量
DECLARE @strAccounts NVARCHAR(32)
DECLARE @strPhone0 NVARCHAR(31)
DECLARE @IsGuest TINYINT
-- 辅助变量
DECLARE @ErrorDescribe NVARCHAR(128)

-- 执行逻辑
BEGIN
	-- 查询用户
	SELECT @strAccounts=Accounts,@strPhone0=Phone,@IsGuest=IsGuest FROM AccountsInfo(NOLOCK) WHERE UserID=@UserId

	IF @strAccounts IS NULL 
	BEGIN
		SELECT @UserId AS UserID, [ErrorDescribe]=N'帐号不存在！', @strAccounts AS Accounts,@strPhone as Phone
		RETURN 1
	END

	IF @IsGuest<>2
	BEGIN
		SELECT @UserId AS UserID, [ErrorDescribe]=N'不是微信帐号！', @strAccounts AS Accounts,@strPhone as Phone
		RETURN 2
	END

	IF @strPhone0=@strPhone 
	BEGIN
		SELECT @UserId AS UserID, [ErrorDescribe]=N'已经绑定！', @strAccounts AS Accounts,@strPhone as Phone
		RETURN 3
	END
	
	UPDATE AccountsInfo SET Phone=@strPhone WHERE UserID=@UserId
	-- 输出变量
	SELECT @ErrorDescribe AS ErrorDescribe, @strAccounts AS Accounts,@strPhone as Phone
END

RETURN 0


