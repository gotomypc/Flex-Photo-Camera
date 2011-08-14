<script type="text/javascript">
/* <![CDATA[ */
var firstStatusId=<?php echo count($objs) ? $objs[0]->id : 0;?>;
var lastStatusId=<?php echo count($objs) ? $objs[count($objs)-1]->id : 0;?>;
var timeoutStatuses = <?php echo 1000*30;?>;

function sendAJAX(_url, _label)
{
	var l = $('#'+_label);
	var murl = '<?php echo SERVER_ROOT;?>index.php?format=raw&nc='+(new Date().getTime())+'&'+_url;
	l.html('Loading...');
	$.ajax({
		url: murl
		,success: function(data, textStatus, jqXHR){
			l.html('');
			var rv = $(data);
			var isFirst = parseInt( rv.find('#returned_is_first_id').get(0).innerHTML );
			if ( isFirst == 1) //new ones
			{
				var tmp = parseInt( rv.find('#returned_first_id').get(0).innerHTML );
				if ( tmp )
				{
					$('html, body').animate({scrollTop:0}, 'fast');
					firstStatusId = tmp;
					document.getElementById('statuses_conatiner').innerHTML = 
									rv.find('#returned_objs').get(0).innerHTML + 
									document.getElementById('statuses_conatiner').innerHTML;
					
				};
			}
			else if ( isFirst == 2 ) //comments
			{
				var sid = parseInt( rv.find('#returned_status_id').get(0).innerHTML );
				$('#status_comments'+sid).show().html( rv.find('#returned_objs').get(0).innerHTML )
				$(window).scrollTop($('#camera_photo_mblog_entry'+sid).offset().top-10);
			}
			else
			{
				var cnt = parseInt( rv.find('#returned_cnt').get(0).innerHTML );
				
				if ( cnt < <?php echo BLOGS_SHOW_COUNT;?> )
				{
						$('#load_more_statuses').html( 'No more...' );
				}
				else
				{
					lastStatusId = parseInt( rv.find('#returned_last_id').get(0).innerHTML );
				}
				document.getElementById('statuses_conatiner').innerHTML += rv.find('#returned_objs').get(0).innerHTML;
			}
		}
		,error: function(jqXHR, textStatus, errorThrown){
			l.html('');
		}
	});
}

function loadMoreStatuses()
{	
	sendAJAX('last_id='+lastStatusId, 'statuses_ajax_notif');
	return false;
}

function showLargeStatusImage(photo, el)
{
	//$('#upload_part').hide();
	$('#large_status_image_div').remove();
	el = $(el).parent();
	var div = $('<div id="large_status_image_div"></div>').append( $('<img src="<?php echo SERVER_ROOT;?>photos/'+photo+'" alt="" />' ) );
	div.css('position', 'absolute' );
	//div.css('left', el.offset().left );
	//var p = el.offset().top - $(document).scrollTop();
	//div.css('top', p <= 200 ? $(document).scrollTop()  :  $(document).scrollTop() + 150 );
	div.css('top', $(document).scrollTop() + 100 );
	div.css('left', el.offset().left + el.width() );
	if ( $(document).scrollTop() < $(document).height() )
	{
		$('#upload_part').css('marginTop', $(document).height());
	}
	$('body').append(div);
}
function hideLargeStatusImage()
{
	$('#large_status_image_div').remove();
	$('#upload_part').css('marginTop', 0);
}
$(document).ready(function(){
	setTimeout('checkNewStatuses()',timeoutStatuses);
});
function checkNewStatuses()
{
	sendAJAX('first_id='+firstStatusId, 'statuses_ajax_notif');
	setTimeout('checkNewStatuses()',timeoutStatuses);
}

/* ]]> */
</script>