package cameraphoto 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextLineMetrics;
	import flash.utils.Timer;
	import mx.containers.Canvas;
	import mx.containers.ControlBar;
	import mx.containers.Panel;
	import mx.controls.Button;
	import mx.controls.TextArea;
	import mx.core.UIComponent;
	import mx.controls.Label;
	
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
		
		private var videoContainer:Panel;
		
		private var streamUIComponent:UIComponent;
		private var photoUIComponent:UIComponent;
		
		private var saveButton:Button;
		private var takePhotoButton:Button;
		
		private var notificationLabel:Label;
		private var intervalTimer:Timer;
		//this sprite is used as bottom overlay
		private var overlay:Canvas;
		
		private var takingPhotoCounter:Number;
		
		
		private var jsFuncToCall:String = null;
		
		private var fontSize:Number;
		
		private var minimalPhotoEditLength:Number;
		
		private var titlePhotoEditTextArea:TextArea;
		
		public static const STATE_START : Number = 1;
		public static const STATE_TAKE_PHOTO: Number = 2;
		public static const STATE_SAVING_PHOTO : Number = 3;
		public static const STATE_TAKING_PHOTO: Number = 4;
		public static const STATE_PHOTO_SAVED: Number = 5;
		public static const STATE_CANCELED_SAVING_PHOTO: Number = 6;
		private var state:Number;
		
		public function CameraMain(
			suploadPhoto:UploadPhoto, scameraStream:CameraStream, 
			svideo:Panel, ssaveButton:Button, stakePhotoButton:Button,
			titleBox:TextArea,
			sminimalPhotoEditLength:Number,
			swaitForPhotoInterval:Number = WAIT_FOR_PHOTO_INTERVAL,
			swaitForPhotoIntervalDelay:Number = WAIT_FOR_PHOTO_INTERVAL_DELAY, 
			sfontSize:Number = NOTIFICATION_FONT_SIZE ) 
		{
			uploadPhoto = suploadPhoto;
			cameraStream = scameraStream;
			videoContainer = svideo;
			takingPhotoCounter = swaitForPhotoInterval;
			fontSize = sfontSize;
			titlePhotoEditTextArea = titleBox;
			minimalPhotoEditLength = sminimalPhotoEditLength;
			
			saveButton = ssaveButton;
			takePhotoButton = stakePhotoButton;
			takePhotoButton.addEventListener(MouseEvent.CLICK, handlerTakePicture);
			saveButton.addEventListener(MouseEvent.CLICK, handlerSavePhoto);
			
			streamUIComponent = new UIComponent();
			streamUIComponent.width = cameraStream.getWidth();
			streamUIComponent.height = cameraStream.getHeight();
			streamUIComponent.addChild( cameraStream );
			videoContainer.addChild( streamUIComponent );
			
			photoUIComponent = new UIComponent();
			photoUIComponent.width = cameraStream.getWidth();
			photoUIComponent.height = cameraStream.getHeight();
			videoContainer.addChild( photoUIComponent );
			
			notificationLabel = new Label();
			
			var format:TextFormat = new TextFormat();
			format.color = 0xFFFFFF;
						
			notificationLabel.setStyle("color", 0x0ffffff);			

			//videoContainer.addChild(notificationLabel);
			
			//add/create overlay
			overlay = new Canvas();
			overlay.name = "my_overlay";
			overlay.width = videoContainer.width - videoContainer.borderMetrics.left - 1;
			overlay.height = fontSize * 3;
			overlay.y = videoContainer.height - overlay.height - videoContainer.borderMetrics.top - 1;
			//overlay.alpha = 0.75;
			var g:Graphics = overlay.graphics;
			g.beginFill(0x000, 0.7);
			g.drawRect(0, 0, overlay.width, overlay.height);
			g.endFill();
			overlay.addChild(notificationLabel);			
			
			intervalTimer = new Timer(swaitForPhotoIntervalDelay, takingPhotoCounter + 1);
			intervalTimer.addEventListener(TimerEvent.TIMER, handlerPhotoTimer);
			intervalTimer.addEventListener(TimerEvent.TIMER_COMPLETE, handlerPhotoTimerComplete);
			
			//add handlers for upload event
			uploadPhoto.addEventListener('onLoadSuccess', onSuccessPhotoUpload );
			uploadPhoto.addEventListener('onLoadFailure', onFailurePhotoUpload );
			uploadPhoto.addEventListener('onSecurityError', onFailurePhotoUpload );
			
			//default button captions
			saveButton.label = Translator.__("saveButtonLabel");
			takePhotoButton.label = Translator.__("takePhotoButtonLabel");		
			
			//set default/start state
			setState( STATE_START );
		}
		
		private function handlerTakePicture(event:Event):void {
			setState( STATE_TAKING_PHOTO );
			/*
				if ( state == STATE_START )
				{
					setState( STATE_TAKING_PHOTO );	
				}
				else
				{
					setState(STATE_START);
				}
				*/
        }
		
		private function handlerPhotoTimer(event:TimerEvent):void {
			var tmp:Number = parseInt( notificationLabel.text ) - 1;
			notificationLabel.text = tmp > 0 ? tmp.toString() : Translator.__('textBeforeTakingPhoto');
			centerNotif();
        }
		
		private function handlerPhotoTimerComplete(event:TimerEvent):void {
			setState( STATE_TAKE_PHOTO );
        }
		
		private function handlerSavePhoto(event:Event):void {
			
			
			var t:String = titlePhotoEditTextArea != null ? titlePhotoEditTextArea.text : null;
			if ( t != null  &&  t.length < minimalPhotoEditLength )
			{
				Alert.init(photoUIComponent);
				Alert.show( Translator.__('titleNotEnoughLettersError') , { buttons:[Translator.__('okButtonLabel')] } );	
				return;
			}
			//call ducking uploading :)
			setState( STATE_SAVING_PHOTO );
			
			uploadPhoto.upload( cameraStream.getLastSnapShot(), t );
			//this is not working because of security restrictions
			//var t:Timer = new Timer(200, 1);
			//t.addEventListener(TimerEvent.TIMER_COMPLETE, handlerTimerCompleteStartPhotoSave);
			//t.start();
        }
		
		private function centerNotif():void
		{
			//we must measure length of current text in label and center it
			var m:TextLineMetrics = notificationLabel.measureText(notificationLabel.text);
			notificationLabel.y = (overlay.height - m.height) / 2;
			notificationLabel.x = (overlay.width - m.width) / 2;
		}
		
		private function setState(nState:Number):void
		{
			state = nState;
			switch (state)
			{
				case STATE_START:
					cameraStream.clearLastSnapShot();
					streamUIComponent.setVisible(true);
					photoUIComponent.setVisible(false);
			
					//notificationLabel.setVisible(false);
					var s:DisplayObject = videoContainer.getChildByName("my_overlay");
					if ( s != null )
					{
						videoContainer.removeChild(overlay);
					}
					
					saveButton.enabled = false;
					takePhotoButton.enabled = true;
					
					takePhotoButton.label = Translator.__("takePhotoButtonLabel");
					break;
					
				case STATE_TAKING_PHOTO:
					streamUIComponent.setVisible(true);
					photoUIComponent.setVisible(false);
					
					//notificationLabel.setVisible(true);
					videoContainer.addChild(overlay);
					
					saveButton.enabled = false;
					takePhotoButton.enabled = false;
					
					var fSizeTmp:Number =  1.8 * fontSize;
					notificationLabel.setStyle("fontSize", fSizeTmp.toString() );
					notificationLabel.text = takingPhotoCounter.toString();
					centerNotif();
					
					intervalTimer.reset();
					intervalTimer.start();
					break;
					
				case STATE_TAKE_PHOTO:
					streamUIComponent.setVisible(false);
					photoUIComponent.setVisible(true);
					
					addOnlyChild( photoUIComponent, cameraStream.getSnapshot() );
					
					//notificationLabel.setVisible(false);
					videoContainer.removeChild(overlay);

					takePhotoButton.label = Translator.__("takePhotoAgainButtonLabel");		
					
					saveButton.enabled = true;
					takePhotoButton.enabled = true;
			
					break;
					
				case STATE_SAVING_PHOTO:
					streamUIComponent.setVisible(false);
					photoUIComponent.setVisible(true);
					
					//notificationLabel.setVisible(true);
					videoContainer.addChild(overlay);
					
					saveButton.enabled = false;
					takePhotoButton.enabled = false;
										
					notificationLabel.setStyle("fontSize", fontSize.toString() );
					notificationLabel.text = Translator.__('notificationSavingPhoto');
					centerNotif();					
					break;
					
				case STATE_PHOTO_SAVED:
					streamUIComponent.setVisible(false);
					photoUIComponent.setVisible(true);
					
					//notificationLabel.setVisible(true);
					videoContainer.addChild(overlay);
					
					saveButton.enabled = false;
					takePhotoButton.enabled = true;
					
					notificationLabel.setStyle("fontSize", fontSize.toString() );
					notificationLabel.text = Translator.__('notificationPhotoSaved');
					centerNotif();
					
					//if we specify js func to call - call it
					if ( jsFuncToCall != null )
					{
						ExternalInterface.call(jsFuncToCall+"()");
					}
					break;	
			}
		}
		
		public function setJsFuncToCall(f:String):void {
			jsFuncToCall = f;
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
					showErrorNotifAndSetNewState( json.error );
				}
				else
				{
					setState(STATE_PHOTO_SAVED);
				}
			}
			catch (e:Error)
			{
				showErrorNotifAndSetNewState( Translator.__('notificationSavingPhotoFailed') );
			}
			
		}
		
		private function handleResponseAlert(response:String):void {
			state = STATE_TAKE_PHOTO;
			streamUIComponent.setVisible(false);
			photoUIComponent.setVisible(true);
					
			notificationLabel.setVisible(false);

			saveButton.label = Translator.__("saveButtonLabel");
			takePhotoButton.label = Translator.__("takePhotoAgainButtonLabel");		
			
			saveButton.enabled = true;
			takePhotoButton.enabled = true;
		}

		
		private function showErrorNotifAndSetNewState(msg:String):void
		{
			//notificationLabel.setVisible(false);
			videoContainer.removeChild(overlay);

			//show alert with error notification
			//after user clicks on OK button calls handler which will change state of app
			Alert.init(photoUIComponent);
			Alert.show( msg, { buttons:[Translator.__('okButtonLabel')], callback:handleResponseAlert} );		
		}
		
		private function onFailurePhotoUpload(evt:UploadPhotoEvent):void
		{
			showErrorNotifAndSetNewState( Translator.__('notificationSavingPhotoFailed') );
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