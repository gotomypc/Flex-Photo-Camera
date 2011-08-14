<?php
require_once dirname(__FILE__).'/config.php';

require_once dirname(__FILE__).'/icImageHelper.php';
require_once dirname(__FILE__).'/database.php';
/*
#####Create database table with sql bellow#####

CREATE TABLE `photo_log` (
  `id` int(11) NOT NULL auto_increment,
  `photo` varchar(120) NOT NULL,
  `title` varchar(180),
  `time` int(11),
  PRIMARY KEY (`id`),
  INDEX (`time`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin
*/


$db = new Database();

$data = isset($_GET['data']) ? $_GET['data'] : '0-0';
$title = isset($_POST['title']) ? $db->Quote($_POST['title']) : 'null';
$userId = 72;
if ( session_id() == $data){

	$time = time();
	$photoName = $time.'e'.session_id().'o'.mt_rand(0,1000).'.jpg';
	
	$imageHelperObj = new icImageHelper($_FILES['Filedata']);
	if ( !$imageHelperObj->isOk() ) 
	{
		echo '{ "status": 0, "error": "Greska pri uploadu slike" }';
		exit;
	}
	$basePath = dirname(__FILE__);
	$thumbPath = $basePath.'/photos/thumbs/'.$photoName;
	$imgPath = $basePath.'/photos/'.$photoName;
	$imageHelperObj->thumb( 200, 150, $thumbPath );
	$imageHelperObj->save($imgPath);
	$imageHelperObj->destroy();
	$query = "INSERT INTO photo_log (photo,title,time) VALUES('$photoName',$title,$time)";
	$db->setQuery( $query );
	$db->query();
	echo '{ "status": 1 }';
}
else
{
	echo '{ "status": 0, "error": "Invalid session!" }';
}
$db->release();