USE ZQGameUserDB;
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go









---接受任务
create PROCEDURE [dbo].[GSP_GP_GetTask]
	@UserID						INT,					--用户ID
	@KindID						INT						--游戏ID
AS
-- 属性设置
SET NOCOUNT ON

DECLARE @dwUserID			INT						--用户ID
DECLARE	@Grade				INT						--等级
DECLARE	@NeedGradePhase		INT						--等级阶段
DECLARE @Rate				INT						--任务比率
DECLARE @Rand				INT						--随机数
DECLARE @TaskID				INT						--任务ID
DECLARE @Count				INT						--任务数量
DECLARE @TaskUserLogID		INT						--接受任务日志ID

DECLARE @currMonth	NVARCHAR(6)						--当前年月份
DECLARE @currTable	NVARCHAR(24)					--当前表

BEGIN
	--斗地主
	IF(@KindID=10)
	BEGIN
		--用户等级
		SELECT @Grade=Grade,@dwUserID=UserID FROM ZQTreasureDB.dbo.GameScoreInfo WHERE UserID=@UserID
		IF(@Grade IS NOT NULL)
		BEGIN
			--设置任务接受百分比
			IF(@Grade < 16)
				SET @Rate = 50
			ELSE IF(@Grade < 33)
				SET @Rate = 80
			ELSE
				SET @Rate = 100

			--获取任务百分比
			SELECT @Rand = CAST(RAND()*100 AS INT)%@Rate
			--设置等级接受阶段
			IF(@Rand < 50)
				SET @NeedGradePhase = 1
			ELSE IF(@Rand < 80)
				SET @NeedGradePhase = 2
			ELSE
				SET @NeedGradePhase = 3
			--获取任务总数量
			SELECT @Count=COUNT(*) FROM Task WHERE NeedGradePhase <= @NeedGradePhase
			IF(@Count > 0)
			BEGIN
				--获取随机任务ID号
				SELECT @TaskID=MAX(ID) FROM Task WHERE ID IN 
					(SELECT TOP ((CAST(RAND()*100 AS INT))%@Count + 1) ID FROM Task WHERE NeedGradePhase <= @NeedGradePhase)
				--插入任务日志表
				SELECT @currMonth=LEFT(CONVERT(NVARCHAR(8),GETDATE(),112),6)
				SET @currTable='TaskUserLog_'+@currMonth
				IF NOT EXISTS(SELECT * FROM ZQGameUserDB.DBO.SYSOBJECTS WHERE name=@currTable)
				BEGIN
					EXEC ('CREATE TABLE '+@currTable+'(
							[id] [int] IDENTITY(1,1) NOT NULL,
							[UserID] [int] NOT NULL,
							[TaskID] [int] NOT NULL,
							[Flag] [TINYINT] NOT NULL DEFAULT (1),
							[CreateDate] [datetime] NOT NULL DEFAULT (getdate()),
							CONSTRAINT [PK_'+@currTable+'] PRIMARY KEY CLUSTERED 
							(
								[id] ASC
							)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
						) ON [PRIMARY]
					')
				END
/*
				--------------------------------------------测试任务-----------------------------------------
				DECLARE @surTaskID		INT
				DECLARE @Flag			TINYINT
				DECLARE @logID			INT
				SELECT TOP 1 @logID=ID,@surTaskID = TaskID, @Flag = Flag FROM TaskUserLog_201110 WHERE UserID = @UserID ORDER BY ID DESC
				IF (@Flag=1)
				BEGIN
					SELECT TOP 1 a.ID AS dwTaskID,b.Name AS Title,a.Name AS Context,LargessCount1,LargessCount2,LargessCount3,
					LargessCount4,@logID AS TaskUserLogID,@currTable AS TaskUserLogTable,@dwUserID AS dwUserID
					FROM Task a LEFT JOIN TaskType b ON a.TaskTypeID=b.ID WHERE a.ID=@surTaskID
				END
				ELSE
				BEGIN
					SELECT @TaskID=MAX(ID) FROM Task WHERE ID IN 
					(SELECT TOP ((SELECT COUNT(*) FROM TaskUserLog_201110 WHERE UserID=@UserID) + 1) ID FROM Task)

					EXEC ('INSERT INTO '+@currTable+'(UserID,TaskID) VALUES	('+@UserID+','+@TaskID+')')
					SET @TaskUserLogID=@@IDENTITY

					SELECT TOP 1 a.ID AS dwTaskID,b.Name AS Title,a.Name AS Context,LargessCount1,LargessCount2,LargessCount3,
					LargessCount4,@TaskUserLogID AS TaskUserLogID,@currTable AS TaskUserLogTable,@dwUserID AS dwUserID
					FROM Task a LEFT JOIN TaskType b ON a.TaskTypeID=b.ID WHERE a.ID=@TaskID
				END
				---------------------------测试完成删除此段，并且删除以下注释---------------------------------------------------
*/

				--新增任务日志
				EXEC ('INSERT INTO '+@currTable+'(UserID,TaskID) VALUES	('+@UserID+','+@TaskID+')')
				SET @TaskUserLogID=@@IDENTITY

				--输出任务数据
				SELECT TOP 1 a.ID AS dwTaskID,b.Name AS Title,a.Name AS Context,LargessCount1,LargessCount2,LargessCount3,
					LargessCount4,@TaskUserLogID AS TaskUserLogID,@currTable AS TaskUserLogTable,@dwUserID AS dwUserID
					FROM Task a LEFT JOIN TaskType b ON a.TaskTypeID=b.ID WHERE a.ID=@TaskID

				RETURN 1
			END
		END
	END
	RETURN 0
END









