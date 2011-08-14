package cameraphoto 
{
	import flash.display.Sprite;
    import flash.display.DisplayObject;
    import flash.geom.Matrix;	
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	import adobe.images.*;
	import marston.utils.URLRequestWrapper;
	/**
	 * ...
	 * @author Igor Crevar
	 * based on ....
	 */
	public class UploadPhoto extends Sprite
	{
		private var scriptUrl:String;
		private var wrapper:URLRequestWrapper;
		private var ldr:URLLoader;
		
		public function UploadPhoto(scriptUrl:String) 
		{
			this.scriptUrl = scriptUrl;
		}
		
		public function upload(bitmapData:BitmapData, title:String = null):void
		{
			var byteArray:ByteArray = new JPGEncoder().encode(bitmapData);
			var fileName:String = Math.round(100) + "e" + (new Date().valueOf().toString()) + ".jpg";
			
			var params:Object = null;
			if ( title != null )
			{
				params = new Object();
				params.title = title;
			}
			
			wrapper = new URLRequestWrapper(byteArray, fileName, null, params );
		    wrapper.url = scriptUrl;
			
            ldr = new URLLoader();
			ldr.dataFormat = URLLoaderDataFormat.BINARY;
			ldr.addEventListener(Event.COMPLETE, onLoadSuccess);
			ldr.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			try
			{
				ldr.load(wrapper.request);
			}
			catch (ex:SecurityError)
			{
				dispatchEvent( new UploadPhotoEvent('onSecurityError', 'Security Violation') );
			}
		}
		
		
		private function onLoadSuccess(evt:Event):void
		{
			trace("OK");
			dispatchEvent( new UploadPhotoEvent('onLoadSuccess', evt.target) );
		}
		
		private function ioErrorHandler(evt:IOErrorEvent):void
		{
			trace("ERROR IO");
			dispatchEvent( new UploadPhotoEvent('onLoadFailure', 'IO Error.'));
		}
		
		private function onSecurityError(evt:SecurityErrorEvent):void
		{
			trace("ERROR SEC");
			dispatchEvent( new UploadPhotoEvent('onSecurityError', 'Security Violation') );
		}
		
		
	}

}