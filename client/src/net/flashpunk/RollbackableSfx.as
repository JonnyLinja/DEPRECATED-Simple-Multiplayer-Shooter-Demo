package net.flashpunk {
	import net.flashpunk.Sfx;
	import net.flashpunk.Rollbackable;
	
	import flash.events.Event;
	
	public class RollbackableSfx extends Sfx implements Rollbackable {
		//delegate
		public var getStartFrame:Function;
		
		//private vars
		internal var startFrame:uint = 0; //temp debug internal
		private var shouldPlayVol:Number = 1;
		private var shouldPlayPan:Number = 0;
		private var shouldPlayPosition:Number = 0;
		private var shouldStartFrame:uint = 0;
		
		//datastructure
		internal var next:RollbackableSfx = null;
		
		public function RollbackableSfx(source:*, complete:Function = null, type:String = null) {
			//super
			super(source, complete, type);
		}
		
		//reset
		private function reset():void {
			shouldPlayVol = 1;
			shouldPlayPan = 0;
			shouldPlayPosition = 0;
		}
		
		//complete
		override internal function onComplete(e:Event = null):void {
			//super
			super.onComplete();
			
			//reset so render won't play it
			reset();
		}
		
		//play
		override public function play(vol:Number = 1, pan:Number = 0, pos:Number = 0):void {
			shouldStartFrame = getStartFrame();
			shouldPlayVol = vol;
			shouldPlayPan = pan;
			shouldPlayPosition = 0;
		}
		
		//stop 
		
		//resume
		
		//loop
		
		//render
		public function render(frame:Number, frameRate:Number):void {
			if (startFrame < shouldStartFrame) {
				//start it
				
				//determine can play
				if (frame < shouldStartFrame)
					return;
				
				//set frames
				startFrame = shouldStartFrame;
				
				//calculate start pos
				var pos:Number = shouldPlayPosition + ((frame - startFrame) * frameRate);
				
				if (pos > length * 1000) {
					//reset, rolled back to completed sund
					reset();
				}else {
					//play it with initial position
					super.play(shouldPlayVol, shouldPlayPan, pos);
				}
			}else if (startFrame > shouldStartFrame) {
				//stop it - perceived world played sound that should never have been played
				
				//set equal to prevent
				startFrame = shouldStartFrame;
				
				//super
				super.stop();
			}
		}
		
		//rollback
		public function rollback(orig:Rollbackable):void {
			//cast
			var s:RollbackableSfx = orig as RollbackableSfx;
			
			//rollback
			shouldPlayVol = s.shouldPlayVol;
			shouldPlayPan = s.shouldPlayPan;
			shouldPlayPosition = s.shouldPlayPosition;
			shouldStartFrame = s.shouldStartFrame;
		}
	}
}