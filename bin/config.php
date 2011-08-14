<?php
define( 'CREW', 1 );
ini_set('display_errors', 1);
error_reporting(E_ALL);
$type = isset($_REQUEST['format']) ? $_REQUEST['format'] : 'html';
$isAjax = $type == 'raw';

define('DB_HOST','localhost');
define('DB_USER','root');
define('DB_PASSWORD','');
define('DB_NAME','efull'); //db name
define('DB_PREFIX',''); //do not change in most cases
define('BLOGS_SHOW_COUNT', 10);

define('SERVER_ROOT', '/flashphoto/bin/' ); //root dir on server - must have / on the end