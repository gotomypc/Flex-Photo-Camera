<?php 
function showOne($obj) { ?>

<div style="width:460px;padding:5px;border:1px dotted #666;text-align:left;background:#DFDFCF;margin-bottom:10px" id="camera_photo_mblog_entry<?php echo $obj->id;?>">
	<div style="float:left;width:210px">
		<a href="#" onclick="return false" onmouseout="hideLargeStatusImage();" onmouseover="showLargeStatusImage('<?php echo $obj->photo;?>', this);">
			<img src="<?php echo SERVER_ROOT;?>photos/thumbs/<?php echo $obj->photo;?>" alt="" />
		</a>
	</div>
	
	<div style="float:left;font-size:14px;width:250px;overflow:hidden">
		<div style="width:100%;margin-bottom:10px;float:right">
		
			<div style="float:right; width:100px; font-style: italic;text-align:right">
				at <?php echo date('m/d/Y', $obj->time);?>
				<br />				
			</div>
			
			<br />
			<?php echo nl2br($obj->title);?>
			
			<div style="clear:both"></div>
		</div>
		
	</div>
	
	<div style="clear:left"></div>
	
	<div id="status_comments<?php echo $obj->id;?>" style="display:none;text-align:right;">
	</div>
	
</div>
<?php } ?>