<?php

class icImageHelper{
	var $src = false;
	var $width;
	var $height;
	var $valid = array( 'jpg', 'jpeg', 'gif', 'png' );
	var $ext;

	public function __construct( $path, $ext = false )
	{
		if ( !is_null($path) )
		{
			$this->init($path, $ext);
		}
	}
	
	public function init($path, $ext = false )
	{
		if ( $this->src )
		{
			$this->destroy();
		}
		
		if ( is_array($path) )
		{			
			if ( !count($path) || $path['error'] != UPLOAD_ERR_OK ) 
			{
				return $this;	
			}
			if ( !$ext )
			{
				 $this->ext = self::getExt( $path['name'] );
			}
			else{
				$this->ext = $ext;
			}
			$path = $path['tmp_name'];
			
			//move_uploaded_file( $upload['tmp_name'], $path );
		}
		else
		{
			if (!$ext)
			{ 
				$this->ext = self::getExt( $path );
			}	
			else{
				$this->ext = $ext;
			}	
		}
		
		
		if ( in_array( $this->ext, $this->valid ) )
		{
			
			list( $this->width, $this->height ) = getimagesize( $path );
      		switch ( $this->ext ){
      			case 'jpg': case 'jpeg':
      				$this->src = @imagecreatefromjpeg( $path );
      				break;
      			case 'gif':
      				$this->src = @imagecreatefromgif( $path );
      				break;
      			case 'png':
      				$this->src = @imagecreatefrompng( $path );
      				break;
      		}			
		}
	}
	
	function getHeight(){ return $this->height;}
	function getWidth(){ return $this->width;}
	
	public function setExt($ext){
		$this->ext = $ext;
	}
	
	public static function getExt( $fn ){
		$pos = strrpos( $fn, '.' ); 
		$ext = '';
		if ( $pos !== false  &&  $pos + 1 < strlen($fn) ){
      		$ext = strtolower( substr( $fn, $pos+1 ) );
    	}
    	return $ext;
	}
	
	public function isOk(){
		return $this->src !== false;
	}

	public function thumb( $width, $height, $target, $type = null ){
		if ( !$type )
		{
			$type = 'jpg';
		}
		$type = (string)$type;
		//in case extension begins with dot(.)
		if ( $type[0] == '.' )
		{
			$type = substr($type, 1);
		}
		
		$calc = $this->calc($width, $height);
		$nWidth = $calc['w'];
		$nHeight = $calc['h'];
		$startX = $startY = 0;
		//$startX = intval( ($width - $nWidth) / 2 );
		//$startY = intval( ($height - $nHeight) / 2 );
		$dst = ImageCreateTrueColor( $nWidth, $nHeight); //$width, $height );
		$whiteColor = imagecolorallocate($dst, 255, 255, 255);
		imagefill($dst, 0, 0, $whiteColor);
		imagecopyresampled( $dst, $this->src, $startX, $startY, 0, 0, $nWidth, $nHeight, $this->width, $this->height );
 		if ($type == 'png'){
 			imagepng( $dst, $target, 0 );
 		}
		else if ($type == 'gif') imagegif( $dst, $target );
		else imagejpeg( $dst, $target, 100 );
 		imagedestroy( $dst );
 		return $this;
	}
	
	
	public function shrink( $maximum ){
		if ( $this->width <= $maximum  &&  $this->height <= $maximum ) return false;
		if ( $this->width >= $this->height ){
			$width = $maximum;
			$height = (int)($width *  $this->height / $this->width );
 		}
	  	else{  	   		  	   	
 			$height = $maximum;
 			$width = (int)($height * $this->width / $this->height );
		}  				
		$dst = ImageCreateTrueColor( $width, $height );
		imagecopyresampled( $dst, $this->src, 0, 0, 0, 0, $width, $height, $this->width, $this->height );
 		imagedestroy( $this->src );
 		$this->src = $dst;
 		return true;
	}

	public function calc( $thumbW = 100, $thumbH = 75 ){
		if ($this->width < $thumbW) $thumbW = $this->width;
		if ($this->height < $thumbH) $thumbH = $this->height; 
	 	//if ( $this->width >= $this->height )
	 	{
 		 	$tmpH = (int)( $thumbW * $this->height / $this->width );	 
		 	$tmpW = $thumbW;
 			if ( $tmpH > $thumbH ){			 	 		 	
 				$tmpH = $thumbH;
 				$tmpW = (int)( $thumbH * $tmpW / $tmpH );
 			}
 			
	 		if ( $tmpW > $thumbW ){			 	 		 	
 				$tmpW = $thumbW; 
 				$tmpH = (int)( $thumbW * $this->height / $this->width );
 			}
 		}
	  //else{  	   		  	   	
 			//$tmpH = $thumbH;
 			//$tmpW = (int)( $thumbH * $this->width / $this->height );
  	//}  		
		return array( 'w' => $tmpW, 'h' => $tmpH );
	}

	//image must be png because watermark is transparent
	public function addWatermark( $path, $xInc=0, $yInc=16 ){
		if ( !file_exists( $path ) ) return false;
		$watermark = imagecreatefrompng( $path );
		$width = imagesx( $watermark );  
		$height = imagesy( $watermark );    
		$x = $this->width - $width + $xInc;
		$y = $this->height - $height + $yInc;  
		imagecopy( $this->src, $watermark, $x, $y, 0, 0, $width, $height );
		imagedestroy( $watermark );   
		return true;     
	}
	
	public function save( $path, $type = null ){
		
		if ( !$type )
		{
			$type = 'jpg';
		}
		$type = (string)$type;
		//in case extension begins with dot(.)
		if ( $type[0] == '.' )
		{
			$type = substr($type, 1);
		}
		if ($type == 'png'){
			//imagealphablending($this->src, false);
			//imagesavealpha($this->src, true);
			imagepng( $this->src, $path, 0 );
		}
		else if ($type == 'gif') imagegif( $this->src, $path );
		else imagejpeg( $this->src, $path, 100 );
	}
	
	public function destroy(){
		if ( $this->src ){
			imagedestroy( $this->src );
		}
		$this->src = false;
	}
	
	public function __destruct(){ //only for php5

		$this->destroy();
	}

}