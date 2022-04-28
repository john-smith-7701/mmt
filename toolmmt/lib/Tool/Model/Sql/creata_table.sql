-- MySQL dump 10.13  Distrib 8.0.23, for Linux (x86_64)
--
-- Host: qweer.info    Database: YourDB
-- ------------------------------------------------------
-- Server version	8.0.3-rc-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `chatdata`
--

DROP TABLE IF EXISTS `chatdata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chatdata` (
  `SEQ_NO` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL DEFAULT '',
  `chat` text NOT NULL,
  `email` varchar(50) NOT NULL DEFAULT '',
  `host` varchar(30) NOT NULL DEFAULT '',
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`SEQ_NO`)
) ENGINE=MyISAM AUTO_INCREMENT=90792 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `menu_config`
--

DROP TABLE IF EXISTS `menu_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu_config` (
  `SEQ_NO` int(11) NOT NULL AUTO_INCREMENT,
  `ID` varchar(50) NOT NULL,
  `No` varchar(20) NOT NULL,
  `メニュー区分` varchar(10) NOT NULL,
  `menu_ID` varchar(50) NOT NULL,
  `名称` varchar(100) NOT NULL,
  `追加パラメータ` varchar(100) NOT NULL,
  `memo` text NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `権限` varchar(20) NOT NULL,
  PRIMARY KEY (`SEQ_NO`)
) ENGINE=InnoDB AUTO_INCREMENT=124 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `menu_item`
--

DROP TABLE IF EXISTS `menu_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu_item` (
  `SEQ_NO` int(11) NOT NULL AUTO_INCREMENT,
  `ID` varchar(50) NOT NULL,
  `名称` varchar(50) NOT NULL,
  `略称` varchar(50) NOT NULL,
  `URL` varchar(100) NOT NULL,
  `PARAM` varchar(100) NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `権限` varchar(20) NOT NULL,
  PRIMARY KEY (`SEQ_NO`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `session`
--

DROP TABLE IF EXISTS `session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `session` (
  `session` varchar(100) NOT NULL,
  `user` varchar(100) NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`session`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_group`
--

DROP TABLE IF EXISTS `user_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_group` (
  `id` varchar(50) NOT NULL,
  `groupId` varchar(50) NOT NULL,
  `allow` varchar(30) NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`,`groupId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_info`
--

DROP TABLE IF EXISTS `user_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_info` (
  `userid` varchar(16) NOT NULL,
  `名前` varchar(30) NOT NULL,
  `ニックネーム` varchar(30) NOT NULL,
  `郵便番号` varchar(15) NOT NULL,
  `住所` varchar(50) NOT NULL,
  `電話番号` varchar(20) NOT NULL,
  `メール` varchar(50) NOT NULL,
  `URL` varchar(100) NOT NULL,
  `メモ` text NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`userid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_schedule`
--

DROP TABLE IF EXISTS `user_schedule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_schedule` (
  `SEQ_NO` int(11) NOT NULL AUTO_INCREMENT,
  `userid` varchar(16) NOT NULL,
  `日付` date NOT NULL,
  `時刻` time NOT NULL,
  `予定` varchar(20) NOT NULL,
  `場所` varchar(20) NOT NULL,
  `メモ` text NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`SEQ_NO`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_tbl`
--

DROP TABLE IF EXISTS `user_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_tbl` (
  `userid` varchar(16) NOT NULL DEFAULT '',
  `password` varchar(50) DEFAULT NULL,
  `id` int(11) NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=ujis;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `分類`
--

DROP TABLE IF EXISTS `分類`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `分類` (
  `分類コード` varchar(10) NOT NULL,
  `分類名` varchar(50) NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`分類コード`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `分類名称`
--

DROP TABLE IF EXISTS `分類名称`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `分類名称` (
  `大分類` varchar(10) NOT NULL,
  `中分類` varchar(10) NOT NULL,
  `小分類` varchar(10) NOT NULL,
  `分類名` varchar(30) NOT NULL,
  `略称` varchar(10) NOT NULL,
  `集計1` char(7) NOT NULL,
  `集計2` char(7) NOT NULL,
  `集計3` char(7) NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`大分類`,`中分類`,`小分類`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `商品`
--

DROP TABLE IF EXISTS `商品`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `商品` (
  `商品コード` decimal(16,0) NOT NULL DEFAULT '0',
  `品名` char(30) DEFAULT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `上代` decimal(9,0) NOT NULL,
  `原価` decimal(9,0) NOT NULL,
  `商品区分` char(2) NOT NULL,
  `大分類` char(4) NOT NULL,
  `中分類` char(4) NOT NULL,
  `小分類` char(4) NOT NULL,
  PRIMARY KEY (`商品コード`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `市町村`
--

DROP TABLE IF EXISTS `市町村`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `市町村` (
  `団体コード` varchar(10) NOT NULL,
  `都道府県名` varchar(50) NOT NULL,
  `市区町村名` varchar(50) NOT NULL,
  `都道府県名カナ` varchar(50) NOT NULL,
  `市区町村名カナ` varchar(50) NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`団体コード`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `構成表`
--

DROP TABLE IF EXISTS `構成表`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `構成表` (
  `親部品コード` varchar(20) NOT NULL DEFAULT '',
  `子部品コード` varchar(20) NOT NULL DEFAULT '',
  `員数` decimal(10,0) NOT NULL,
  `乗数` decimal(10,0) NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`親部品コード`,`子部品コード`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `部品`
--

DROP TABLE IF EXISTS `部品`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `部品` (
  `部品コード` varchar(20) NOT NULL DEFAULT '',
  `部品名` varchar(40) NOT NULL,
  `UPD_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `仕様` varchar(80) NOT NULL,
  `備考` varchar(80) NOT NULL,
  `URL` varchar(120) DEFAULT NULL,
  `予備` varchar(80) NOT NULL,
  PRIMARY KEY (`部品コード`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-04-29  7:05:07
