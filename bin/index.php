<?php
require_once dirname(__FILE__).'/config.php';

require_once dirname(__FILE__).'/database.php';

$db = new Database();

$lastId = isset($_REQUEST['last_id']) ? $_REQUEST['last_id'] : 0;
$firstId = isset($_REQUEST['first_id']) ? $_REQUEST['first_id'] : 0;

$query = 'SELECT * FROM photo_log';
if ( $firstId ) $query .= ' WHERE id>'.$firstId;
else if ($lastId ) $query .= ' WHERE id<'.$lastId;
$query .= ' ORDER BY id DESC LIMIT '.BLOGS_SHOW_COUNT;
$db->setQuery( $query );
$objs = $db->loadObjectList();
require_once dirname(__FILE__).'/showone.php';

if (!$isAjax) : 
?>
<script src="<?php echo SERVER_ROOT;?>js/swfobject.js" type="text/javascript"></script>
<script src="<?php echo SERVER_ROOT;?>js/jquery.js" type="text/javascript"></script>
<style type="text/css">
	a{
		border:none;
	}
	a:hover{
	border:none;
	}
	a img{
	border:none;
	}
</style>
<?php require_once dirname(__FILE__).'/display.php';?>


	<div style="width:1000px;overflow:hidden; margin:0 auto;">
		<div style="float:left;width:490px;">
			<div id="statuses_conatiner">
				<?php if ( !count($objs) ) : ?>
					Empty... :(
				<?php endif; ?>
				<?php foreach ($objs as $obj) : ?>
				<?php showOne($obj);?>
				<?php endforeach ;?>

			</div>
			<div style="text-align:center;font-size:14px;" id="load_more_statuses">
				<?php if ( count( $objs) >= BLOGS_SHOW_COUNT ) : ?>
				<a style="font-size:14px;border:1px solid #AAA;padding:4px;" href="#" onclick="return loadMoreStatuses();">older...</a>
				<?php endif; ?>
			</div>
			<div style="text-align:center;font-size:14px;" id="statuses_ajax_notif"></div>
		</div>
		<div style="float:left;width:510px" id="upload_part">
			<?php require_once dirname(__FILE__).'/upload_form.php';?>
		</div>
	</div>
<?php else : 
		  echo '<div>';
		  echo '<div id="returned_is_first_id">'.($firstId ? 1 : 0).'</div>';
		  echo '<div id="returned_first_id">'.( count($objs) ? $objs[0]->id : '').'</div>';
		  echo '<div id="returned_last_id">'.( count($objs) ? $objs[count($objs)-1]->id : '').'</div>';
		  echo '<div id="returned_cnt">'.count($objs).'</div>';
		  echo '<div id="returned_objs">';
		  foreach ($objs as $obj) :
			showOne($obj);
		  endforeach ;
	      echo '</div>';
		  echo '</div>';

endif;?>
<?php

