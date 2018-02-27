CREATE DATABASE  IF NOT EXISTS `skynet` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `skynet`;
-- MySQL dump 10.13  Distrib 5.5.58, for debian-linux-gnu (x86_64)
--
-- Host: 127.0.0.1    Database: skynet
-- ------------------------------------------------------
-- Server version	5.5.58-0ubuntu0.14.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user` (
  `uid` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(16) NOT NULL,
  `loginpass` varchar(32) NOT NULL,
  `nick_name` varchar(45) NOT NULL,
  `bankpass` varchar(45) DEFAULT '888888',
  `email` varchar(255) DEFAULT '123@456.com',
  `sex` char(1) DEFAULT '1',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `coin` int(11) DEFAULT '0',
  `card` int(11) DEFAULT '0',
  `touxian` int(11) DEFAULT '1',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'1234','1234','123455','888888','nil','n','0000-00-00 00:00:00',10011,4,2),(2,'123','123','123456','888888','nil','1','0000-00-00 00:00:00',1000,4,2),(3,'jume','123','123','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(4,'jumee3','123','123','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(5,'jume2003','123456','123456','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(6,'dfgdfg','sdfsadf','sfsadf','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(7,'ddsds','asdasd','sdasdasd','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(8,'sdfsdf','sdfsdf','sdfsdf','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(9,'123232','34343','3434','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(10,'sdfasdfasdf','asdfsadfasd','sadfasdf','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(11,'ssssf','sdfasdf','adfsdaf','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(12,'sdfsd','sdfsd','asdf','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(13,'eewwe','dfgdfgdf','dfgdfg','888888','nil','1','0000-00-00 00:00:00',23,4,1),(14,'123123123','23123123','12312312312','888888','nil','1','0000-00-00 00:00:00',2342,4,1),(15,'sdfds','cxvx','xcv','888888','nil','1','0000-00-00 00:00:00',1000345,4,1),(16,'1234','1234','1234','888888','nil','1','0000-00-00 00:00:00',456,4,1),(17,'qqq','qqq','qqq','888888','nil','1','0000-00-00 00:00:00',1005670,4,1),(18,'qweqwe','qweqwe','qweqwe','888888','nil','1','0000-00-00 00:00:00',1007680,4,1),(19,'qweqweqwe','werwerwer','werwer','888888','nil','1','0000-00-00 00:00:00',234,4,1),(20,'fgdhfgh','gdfg','','888888','nil','1','0000-00-00 00:00:00',1000,4,1),(21,'rtyrtyrty','rtyrtyrty','rtyrtyrty','888888','nil','1','0000-00-00 00:00:00',1000,4,1);
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-02-02 23:38:59
