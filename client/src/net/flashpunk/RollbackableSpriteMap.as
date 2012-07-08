package net.flashpunk {
	import net.flashpunk.Rollbackable;
	import net.flashpunk.graphics.Spritemap;
	
	public class RollbackableSpriteMap extends Spritemap implements Rollbackable {
		public function RollbackableSpriteMap(source:*, frameWidth:uint = 0, frameHeight:uint = 0, callback:Function = null) {
			super(source, frameWidth, frameHeight, callback);
		}
		
		public function rollback(orig:Rollbackable):void {
			//declare variables
			var s:Spritemap = orig as Spritemap;
			
			//complete
			complete = s.complete;
			
			//frame
			frame = s.frame;
			
			//animation frame
			if (s.currentAnim) {
				play(s.currentAnim);
				index = s.index;
			}
			
			//alpha
			alpha = s.alpha;
			
			//tint
			tinting = s.tinting;
			tintMode = s.tintMode;
			
			//color
			color = s.color;
		}
	}
}