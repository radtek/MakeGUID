use ZQGameUserDB;
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go






create PROCEDURE [dbo].[GSP_GP_GetPlacard]
	--获取公告
	@state								TINYINT						--消息类型
AS

BEGIN
	--消息内容
	SELECT TOP 20 Context FROM PlacardCommon WHERE State=@state AND Flag=1 ORDER BY CreateDate DESC

	RETURN @@rowcount
END






