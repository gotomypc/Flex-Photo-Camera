package cameraphoto 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextLineMetrics;
	import flash.utils.Timer;
	import mx.containers.Canvas;
	import mx.containers.ControlBar;
	import mx.containers.Panel;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.TextArea;
	import mx.core.UIComponent;
	import mx.controls.Label;
	import spark.primitives.Rect;
	
	import flash.external.ExternalInterface;
	
	import com.serialization.json.JSON;
	import dVyper.Alert;
	/**
	 * ...
	 * @author Igor Crevar
	 * base idea from: http://blog.tricedesigns.com/2006/06/capturing-still-images-from-camera.html
	 * http://www.quietless.com/kitchen/upload-bitmapdata-snapshot-to-server-in-as3/
	 */
	public class CameraMain 
	{
		public static const WAIT_FOR_PHOTO_INTERVAL : Number = 3;
		public static const WAIT_FOR_PHOTO_INTERVAL_DELAY : Number = 800;
		public static const NOTIFICATION_FONT_SIZE:Number = 30;

		private var cameraStream:CameraStream = null;
		
		private var uploadPhoto:UploadPhoto;
		
		private var videoContainer:Canvas;
		
		private var streamUIComponent:UIComponent;
		private var photoUIComponent:UIComponent;
		
		private var saveButton:Button;
		private var resetButton:Button;
		private var takePhotoButton:Button;
		
		private var notificationLabel:Label;
		private var intervalTimer:Timer = null;
		//this sprite is used as bottom overlay
		private var overlay:Canvas;
		
		private var takingPhotoCounter:Number;
		
		private var afterUploadCallback:String = null;
		private var beforeUploadCallback:String = null;
		
		private var fontSize:Number;
		private var finishAfterUpload:Boolean;
		private var minimalPhotoEditLength:Number;
		
		private var titlePhotoEditTextArea:TextArea;
		
		[Embed("/images/camera.png")] 
		private var cameraIconClass: Class;
		
		public static const STATE_START : Number = 1;
		public static const STATE_PHOTO_TAKEN: Number = 2;
		public static const STATE_SAVING_PHOTO : Number = 3;
		public static const STATE_TAKING_PHOTO: Number = 4;
		public static const STATE_SUCCESSFUL_END: Number = 5;
		public static const STATE_CANCELED_SAVING_PHOTO: Number = 6;
		public static const STATE_SAVING_PHOTO_ERROR: Number = 7;
		private var state:Number;
		
		public function CameraMain(
			suploadPhoto:UploadPhoto, 
			scameraStream:CameraStream, 
			svideo:Canvas,
			safterUploadCallback:String,
			sbeforeUploadCallback:String,
			titleBox:TextArea,
			sminimalPhotoEditLength:Number,
			swaitForPhotoInterval:Number,
			swaitForPhotoIntervalDelay:Number,
			sfinishAfterUpload:Boolean,
			sfontSize:Number) 
		{
			uploadPhoto = suploadPhoto;
			cameraStream = scameraStream;
			videoContainer = svideo;
			takingPhotoCounter = swaitForPhotoInterval;
			fontSize = sfontSize;
			finishAfterUpload = sfinishAfterUpload;
			titlePhotoEditTextArea = titleBox;
			minimalPhotoEditLength = sminimalPhotoEditLength;
			afterUploadCallback = safterUploadCallback;
			beforeUploadCallback = sbeforeUploadCallback;
			
			streamUIComponent = new UIComponent();
			streamUIComponent.width = cameraStream.getWidth();
			streamUIComponent.height = cameraStream.getHeight();
			streamUIComponent.addChild( cameraStream );
			videoContainer.addChild( streamUIComponent );
			
			photoUIComponent = new UIComponent();
			photoUIComponent.width = cameraStream.getWidth();
			photoUIComponent.height = cameraStream.getHeight();
			videoContainer.addChild( photoUIComponent );
			
			//add/create overlay
			overlay = new Canvas();
			overlay.name = "my_overlay";
			overlay.width = videoContainer.width - videoContainer.borderMetrics.left - 1;
			overlay.height = 40;
			overlay.y = videoContainer.height - overlay.height - videoContainer.borderMetrics.top - 1;
			//overlay.alpha = 0.75;
			var g:Graphics = overlay.graphics;
			g.beginFill(0x000, 0.7);
			g.drawRect(0, 0, overlay.width, overlay.height);
			g.endFill();
			
			//timer is only available if photo counter setting is greater than 0 
			if (takingPhotoCounter > 0)
			{
				intervalTimer = new Timer(swaitForPhotoIntervalDelay, takingPhotoCounter + 1);
				intervalTimer.addEventListener(TimerEvent.TIMER, handlerPhotoTimer);
				intervalTimer.addEventListener(TimerEvent.TIMER_COMPLETE, handlerPhotoTimerComplete);
			}
			
			//add handlers for upload event
			uploadPhoto.addEventListener('onLoadSuccess', onSuccessPhotoUpload );
			uploadPhoto.addEventListener('onLoadFailure', onFailurePhotoUpload );
			uploadPhoto.addEventListener('onSecurityError', onFailurePhotoUpload );
			
			//default button captions
			
			saveButton = new Button();
			resetButton = new Button();
			takePhotoButton = new Button();
			takePhotoButton.setStyle("icon", cameraIconClass);
			takePhotoButton.width = takePhotoButton.height = 32;
			takePhotoButton.y = (overlay.height - takePhotoButton.height) / 2;			
			takePhotoButton.x = (overlay.width - takePhotoButton.width) / 2;
			takePhotoButton.addEventListener(MouseEvent.CLICK, handlerTakePicture);
			saveButton.label = Translator.__("saveButtonLabel");
			resetButton.label = Translator.__("resetButtonLabel");				
			saveButton.addEventListener(MouseEvent.CLICK, handlerSave);
			resetButton.addEventListener(MouseEvent.CLICK, handlerReset);
			
			//notification label config
			notificationLabel = new Label();		
			notificationLabel.setStyle("color", 0x0ffffff);
			notificationLabel.setStyle("fontSize", fontSize.toString() );
			
			overlay.addChild(saveButton);
			overlay.addChild(resetButton);
			overlay.addChild(takePhotoButton);
			overlay.addChild(notificationLabel);
			videoContainer.addChild(overlay);
			
			//set default/start state
			setState( STATE_START );
		}

		//method centers notification on bottom of the video stream
		private function centerNotif():void
		{
			//we must measure length of current text in label and center it
			var m:TextLineMetrics = notificationLabel.measureText(notificationLabel.text);
			notificationLabel.y = (overlay.height - m.height) / 2;
			notificationLabel.x = (overlay.width - m.width) / 2;
		}
		
		//caluclate x,y positions of buttons save and reset
		private function initButtonsPos():void
		{
			var rectSave:Rectangle = saveButton.getBounds(saveButton);
			var rectReset:Rectangle = resetButton.getBounds(resetButton);
			saveButton.x = overlay.width - rectSave.width - 10;
			saveButton.y = (overlay.height - rectSave.height) / 2;						
			resetButton.x = overlay.width - rectReset.width - 15 - rectSave.width;
			resetButton.y = (overlay.height - rectReset.height) / 2;
		}
		
		//sets state of app
		private function setState(nState:Number):void
		{
			state = nState;
			switch (state)
			{
				case STATE_START:
					cameraStream.clearLastSnapShot();
					takePhotoButton.setVisible(true);
					saveButton.setVisible(false);
					resetButton.setVisible(false);
					
					streamUIComponent.setVisible(true);
					photoUIComponent.setVisible(false);
					notificationLabel.setVisible(false);
					
					if ( titlePhotoEditTextArea != null )
					{
						titlePhotoEditTextArea.text = "";//clear title
						titlePhotoEditTextArea.enabled = true;						
					}					
					break;
					
				case STATE_TAKING_PHOTO:
					streamUIComponent.setVisible(true);
					photoUIComponent.setVisible(false);
					
					saveButton.setVisible(false);
					resetButton.setVisible(false);
					takePhotoButton.setVisible(false);
					
					notificationLabel.setVisible(true);
					notificationLabel.text = takingPhotoCounter.toString();
					centerNotif();
					
					//show timer with ticks if needed
					if (intervalTimer != null)
					{
						intervalTimer.reset();
						intervalTimer.start();	
					}
					else {
						//otherwise jump to phot taken state
						setState(STATE_PHOTO_TAKEN);
					}
					break;
					
				case STATE_PHOTO_TAKEN:			
					streamUIComponent.setVisible(false);
					photoUIComponent.setVisible(true);
					notificationLabel.setVisible(false);
					//put snapshot to view
					addOnlyChild( photoUIComponent, cameraStream.getSnapshot() );
					
					takePhotoButton.setVisible(false);					
					saveButton.setVisible(true);
					resetButton.setVisible(true);
					initButtonsPos();
					break;
					
				case STATE_SAVING_PHOTO:					
					saveButton.setVisible(false);
					takePhotoButton.setVisible(false);
					resetButton.setVisible(false);
					notificationLabel.setVisible(true);
										
					notificationLabel.text = Translator.__('notificationSavingPhoto');
					centerNotif();	
					break;
				
				case STATE_SAVING_PHOTO_ERROR:
					saveButton.setVisible(true);
					resetButton.setVisible(true);
					takePhotoButton.setVisible(false);
					
					notificationLabel.setVisible(false);				
					break;
					
				case STATE_SUCCESSFUL_END:
					saveButton.setVisible(false);
					resetButton.setVisible(false);
					takePhotoButton.setVisible(false);
					
					if ( titlePhotoEditTextArea != null )
					{
						titlePhotoEditTextArea.enabled = false; //disable text
					}										
					notificationLabel.setVisible(true);
					notificationLabel.text = Translator.__('notificationPhotoSaved');
					centerNotif();
					break;		
			}
		}

		private function handlerTakePicture(event:Event):void {
			setState( STATE_TAKING_PHOTO );
        }
		
		private function handlerPhotoTimer(event:TimerEvent):void {
			var tmp:Number = parseInt( notificationLabel.text ) - 1;
			notificationLabel.text = tmp > 0 ? tmp.toString() : Translator.__('textBeforeTakingPhoto');
			centerNotif();
        }
		
		private function handlerPhotoTimerComplete(event:TimerEvent):void {
			setState( STATE_PHOTO_TAKEN );
        }
		
		private function handlerReset(event:Event):void {
			setState( STATE_START );
        }
		
		private function handlerSave(event:Event):void {
			//no textarea for desc or length of desc is greater than minimal length
			uploadPhotoExecute();
        }
		
		private function uploadPhotoExecute():void {
			if ( titlePhotoEditTextArea == null  ||  titlePhotoEditTextArea.text.length >= minimalPhotoEditLength )
			{
				var params:Object = { };
				if (titlePhotoEditTextArea != null)
				{
					params.title = titlePhotoEditTextArea.text;
				}
				
				//if passed, call js callback to retrieve additional params before uploading
				if (beforeUploadCallback)
				{
					var obj:Object = ExternalInterface.call(beforeUploadCallback);
					for (var i:String in obj) {
						if (obj.hasOwnProperty(i)) {
							params[i] = obj[i];
						}
					}
				}
								
				//call ducking uploading :)
				setState( STATE_SAVING_PHOTO );			
				uploadPhoto.upload( cameraStream.getLastSnapShot(), params);
			}			
			else {
				Alert.init(photoUIComponent);
				Alert.show( Translator.__('titleNotEnoughLettersError') , { buttons:[Translator.__('okButtonLabel')] } );
			}
		}
		
		private function onSuccessPhotoUpload(evt:UploadPhotoEvent):void
		{
			var data:String = evt.params.data != undefined ? evt.params.data : "";
			trace(data);
			try
			{
				var json:* = JSON.deserialize(data);
				trace(json);
				if ( json.status == 0 )
				{
					notificationLabel.setVisible(false);
					showErrorNotification( json.error );
				}
				else
				{
					setState(STATE_SUCCESSFUL_END);	
					//if passed, call external java method
					if (afterUploadCallback)
					{						
						ExternalInterface.call(afterUploadCallback);						
					}
					//if finish... not set roll back all over again!
					else if (!finishAfterUpload)
					{
						notificationLabel.setVisible(false);
						//otherwise show success dialog and on click on ok go back to the begining
						Alert.init(photoUIComponent);
						Alert.show( Translator.__('notificationPhotoSaved'), 
							{ buttons:[Translator.__('okButtonLabel')], callback:function (response:String):void {								
								setState(STATE_START);
						}} );	
					}
				}
			}
			catch (e:Error)
			{
				notificationLabel.setVisible(false);
				showErrorNotification( Translator.__('notificationSavingPhotoFailed') );
			}
		}
		
		private function onFailurePhotoUpload(evt:UploadPhotoEvent):void
		{
			notificationLabel.setVisible(false);
			//TODO: debug?
			showErrorNotification( evt.params + " " + Translator.__('notificationSavingPhotoFailed') );
		}
		
		private function showErrorNotification(msg:String):void
		{
			//show alert with error notification
			//after user clicks on OK button calls handler which will change state of app
			Alert.init(photoUIComponent);
			Alert.show( msg, { buttons:[Translator.__('okButtonLabel')], callback:function (response:String):void {
				setState(STATE_SAVING_PHOTO_ERROR);
			}} );		
		}
		
		//adds child to container  cell
		//all other childs are removing from cell
		private function addOnlyChild(cell:DisplayObjectContainer, obj:DisplayObject):void
		{
			while ( cell.numChildren > 0 )
			{
				cell.removeChildAt( cell.numChildren - 1 );
			} 	
			cell.addChild(obj);
		}
	}
}