package cameraphoto 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	
	/**
	 * ...
	 * @author Igor Crevar
	 * basic idea from: http://blog.tricedesigns.com/2006/06/capturing-still-images-from-camera.html
	 */
	public class CameraStream extends Sprite 
	{

			public static const DEFAULT_CAMERA_FPS : Number = 20;

			private var video:Video;
			private var camera:Camera;

			private var _cameraWidth : Number;
			private var _cameraHeight : Number;
			
			//remebers last taken snapshot
			private var lastSnapshot:BitmapData = null; 
			private var lastSnapshotBitmap:Bitmap = null;

			public function CameraStream(width:Number , fps:Number = DEFAULT_CAMERA_FPS) {
				camera = Camera.getCamera();
				//determine aspect ratio
				if (camera == null) 
				{
					return;
				}
				var aspect:Number = //3 / 4;// 
									camera.height / camera.width;
				camera.setMode(width, aspect * width, fps)
				video = new Video(camera.width, camera.height);
				video.attachCamera(camera);
				addChild(video);

				_cameraWidth = camera.width;
				_cameraHeight = camera.height;
			}

			public function isOk():Boolean
			{
				return camera != null;
			}
			
			public function removeAllFilters():void
			{
				video.filters = [];
			}
			
			public function clearLastSnapShot():void 
			{
				lastSnapshot = null;
				lastSnapshotBitmap = null;
			}
			
			public function getLastSnapShot():BitmapData
			{
				return lastSnapshot;
			}
			
			public function getLastSnapShotBitmap():Bitmap
			{
				return lastSnapshotBitmap;
			}
			
			public function getSnapshot():Bitmap {
				lastSnapshot = null;
				lastSnapshot = new BitmapData(_cameraWidth, _cameraHeight);
				//get this snapshot
				lastSnapshot.draw(video, new Matrix());
				
				//create bitmap because we need too show it
				lastSnapshotBitmap = new Bitmap(lastSnapshot);
				return lastSnapshotBitmap;
			}
			
			public function getWidth():Number
			{
				return _cameraWidth;
			}
			
			public function getHeight():Number
			{
				return _cameraHeight;
			}
		
	}

}