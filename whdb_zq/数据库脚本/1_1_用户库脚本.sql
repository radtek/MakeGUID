USE [master]
GO
/****** 对象:  Database [ZQGameUserDB]    脚本日期: 12/08/2008 11:31:04 ******/
CREATE DATABASE [ZQGameUserDB] ON  PRIMARY 
( NAME = N'ZQGameUserDB', FILENAME = N'G:\whdb_zq\ZQGameUserDB.mdf' , SIZE = 41216KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'ZQGameUserDB_log', FILENAME = N'G:\whdb_zq\ZQGameUserDB_log.LDF' , SIZE = 13632KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
 COLLATE Chinese_PRC_CI_AS
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [ZQGameUserDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [ZQGameUserDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [ZQGameUserDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [ZQGameUserDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [ZQGameUserDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [ZQGameUserDB] SET  READ_WRITE 
GO
ALTER DATABASE [ZQGameUserDB] SET RECOVERY FULL 
GO
ALTER DATABASE [ZQGameUserDB] SET  MULTI_USER 
GO
if ( ((@@microsoftversion / power(2, 24) = 8) and (@@microsoftversion & 0xffff >= 760)) or 
		(@@microsoftversion / power(2, 24) >= 9) )begin 
	exec dbo.sp_dboption @dbname =  N'ZQGameUserDB', @optname = 'db chaining', @optvalue = 'OFF'
 end