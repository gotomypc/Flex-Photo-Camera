<script src="/component/photo/views/camphoto/jquery.js" type="text/javascript"></script>
<script src="/flashphoto/js/swfobject.js" type="text/javascript"></script>

<?php $lang = isset($_SESSION['lang']) ? preg_replace('/[^A-Za-z]/', '', $_SESSION['lang']) : 'en';?>
<script type="text/javascript">
/* <![CDATA[ */
		var flashvars = {
			url: encodeURI("<?php echo SERVER_ROOT;?>submit.php?data=<?php echo session_id();?>"),
			width: 400,
			ticks: 3,
			delay: 500,
			fontSize:20,
			jsFunc: "redirectToIndex",
			langFileUrl: "<?php echo SERVER_ROOT;?>lang/<?php echo $lang;?>.ini",
			maxChars:200
		};
		var params = {
			menu: "false",
			scale: "noScale",
			allowFullscreen: "true",
			allowScriptAccess: "always",
			bgcolor: "#FFFFFF"
		};
		var attributes = {
			id:"CameraPhoto"
		};
		function redirectToIndex()
		{
			window.location = '<?php echo SERVER_ROOT;?>index.php';
		}
		swfobject.embedSWF("<?php echo SERVER_ROOT;?>CameraPhoto.swf", "altContent", '360px', '450px', "10.0.0", 
					"<?php echo SERVER_ROOT;?>expressInstall.swf", flashvars, params, attributes);
		$('#altContent').animate({scrollTop:0}, 'slow');
	/* ]]> */
</script>
	<div id="altContent">
		<p>Web Camera and flash are must have!</p>
		<p><a href="http://www.adobe.com/go/getflashplayer"><img 
			src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" 
			alt="Get Adobe Flash player" /></a></p>
	</div>
