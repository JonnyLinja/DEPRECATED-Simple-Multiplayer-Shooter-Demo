package net.flashpunk {
	import net.flashpunk.Sfx;
	import net.flashpunk.Rollbackable;
	
	public class RollbackableSfx extends Sfx implements Rollbackable {
		//delegate
		public var getStartFrame:Function;
		
		//private vars
		private var shouldPlay:Boolean = false;
		private var shouldPlayVol:Number = 1;
		private var shouldPlayPan:Number = 0;
		private var frame:uint = 0;
		
		//datastructure
		internal var next:RollbackableSfx = null;
		
		public function RollbackableSfx(source:*, complete:Function = null, type:String = null) {
			//super
			super(source, complete, type);
		}
		
		override public function play(vol:Number = 1, pan:Number = 0):void {
			frame = getStartFrame();
			shouldPlay = true;
			shouldPlayVol = vol;
			shouldPlayPan = pan;
		}
		
		//stop
		
		//resume
		
		//loop
		
		public function render():void {
			if (shouldPlay && !playing) {
				//play it with delay
				play(shouldPlayVol, shouldPlayPan);
			}else if (!shouldPlay && playing) {
				//stop it
				stop();
			}
		}
		
		public function rollback(orig:Rollbackable):void {
			//cast
			var s:RollbackableSfx = orig as RollbackableSfx;
			
			//rollback
			frame = s.frame;
			shouldPlay = s.shouldPlay;
			shouldPlayVol = s.shouldPlayVol;
			shouldPlayPan = s.shouldPlayPan;
		}
	}
}