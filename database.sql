CREATE DATABASE efull;
USE efull;
CREATE TABLE `photo_log` (
  `id` int(11) NOT NULL auto_increment,
  `photo` varchar(120) NOT NULL,
  `title` varchar(180),
  `time` int(11),
  PRIMARY KEY (`id`),
  INDEX (`time`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin