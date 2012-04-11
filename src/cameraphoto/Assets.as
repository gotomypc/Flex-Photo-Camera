package cameraphoto 
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Igor Crevar
	 */
	public class Assets 
	{		
		private static var instance:Assets;
		private var images:Dictionary = new Dictionary();
		private var currentIndex:int = 0;
		
		private function loadImagesStep():void
		{
			currentIndex++;
			switch (currentIndex)
			{
				case 1:
				loadImage("images/camera-icon.png", "camera");
				break;
			}
		}
		
		private function loadImage(url:String, key: String):void
		{
			var currentLoader:Loader = new Loader();
			currentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function (event:Event):void {
				images[key] = currentLoader;
				loadImagesStep();
			});
			
			currentLoader.load(new URLRequest(url));
		}
		
		/*
		 * Assets is singleton class
		 */
		public static function getInstance():Assets 
		{
			if (instance == null)
			{
				instance = new Assets();
				instance.loadImagesStep();
			}
			
			return instance;
		}
		
		/*
		 * Retrieve image by key
		 */
		public function getImage(key:String):Loader
		{
			return typeof images[key] != "undefined" ? images[key] : null;
		}
		
	}

}