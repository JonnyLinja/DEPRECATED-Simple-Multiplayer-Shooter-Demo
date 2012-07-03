package net.flashpunk.rollback {
	import net.flashpunk.rollback.Command;	
	import net.flashpunk.RollbackableWorld;
	import net.flashpunk.Rollbackable;
	
	public class GameWorld extends RollbackableWorld {
		private var _frameRate:uint;
		private var _frameElapsed:Number;
		private var _frame:uint = 0;
		
		public function GameWorld(frameRate:uint) {
			//super
			super();
			
			//save frame rate
			_frameRate = frameRate;
			_frameElapsed = frameRate * .001;
		}
		
		/**
		 * Getter
		 */
		public function get frameRate():uint {
			return _frameRate;
		}
		
		/**
		 * Getter
		 */
		public function get frameElapsed():Number {
			return _frameElapsed;
		}
		
		/**
		 * Getter
		 */
		public function get frame():uint {
			return _frame;
		}
		
		/**
		 * Children should override
		 * @param	c
		 */
		public function executeCommand(c:Command):void {
		}
		
		/**
		 * Update also handles updateLists
		 */
		override public function update():void {
			//update entities created by commands
			updateLists();
			
			//super
			super.update();
			
			//update entities affected by collisions
			updateLists();
			
			//increment
			_frame++;
		}
		
		override public function rollback(orig:Rollbackable):void {
			//super
			super.rollback(orig);
			
			//cast
			var g:GameWorld = orig as GameWorld;
			
			//frames
			_frame = g._frame;
		}
	}
}