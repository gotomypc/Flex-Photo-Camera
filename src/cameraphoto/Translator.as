package cameraphoto 
{
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.events.Event;
	import flash.net.URLRequest;
	/**
	 * ...
	 * @author Igor Crevar
	 */
	public class Translator 
	{
		private static var loader:URLLoader;
		private static var map:Array = new Array();
		private static var functoCallAfterLoading:Function;
		
		public static function init(langFileUrl:String, functoCallAfterLoading:Function) :void
		{
			Translator.functoCallAfterLoading = functoCallAfterLoading;
			//loaf txt
			loader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, Translator.onLangFileLoadedHandler);
			
			//must handle io error
			loader.addEventListener(IOErrorEvent.IO_ERROR, Translator.onLangFileLoadedHandlerioError);
			
			if ( langFileUrl == null )
			{
				langFileUrl = "lang/en.ini";
			}
			try
			{
				loader.load( new URLRequest(langFileUrl) );
			}
			catch (e:Error)
			{
				//if we got exception dispatch to our function imediatelly
				Translator.functoCallAfterLoading();
			}
		}
		
		//returns value for a key
		public static function __(key:String):String
		{
			key = key.toLowerCase();
			return Translator.map[key] != undefined ? Translator.map[key] : key;
		}
		
		private static function onLangFileLoadedHandler(event:Event):void
		{
			Translator.parse( event.target.data as String );
			Translator.functoCallAfterLoading();
		}
		
		private static function  onLangFileLoadedHandlerioError(evt:IOErrorEvent):void
		{
			trace("ERROR Loading lang file");
			Translator.functoCallAfterLoading();
		}
		
		
		private static function parse(str:String):void
		{
			var lines:Array = str.split("\n");
			var lastKey:String = null;
			var i:int;
			
			//trace(lines); return;
			for (i = 0; i < lines.length; ++i)
			{
				var line:String = lines[i];
				
				//remove spaces on start and ending and carriage return 
				line = line.replace(/\r/, '').replace(/^\s*/g, '').replace(/\s*$/, '');
				//empty lines and lines start with #(comments) are skipped
				if ( line.length == 0 || line.substr(0,1) == '#' ) continue;
				//if line doesnt have = than its not property line
				if ( line.indexOf('=') == -1 )
				{
					//should i add to prev key?
					if ( lastKey != null )
					{
						Translator.map[lastKey] += "\r\n" + line;
					}
					continue;
				}
				var property:Array = line.split("=", 2);
				var key:String = (property[0] as String).toLowerCase();
				Translator.map[key] = property[1];
				lastKey = key;
			}
		
		}
	}
}