package net.flashpunk.rollback {
	import net.flashpunk.rollback.Command;	
	import net.flashpunk.RollbackableWorld;
	
	public class GameWorld extends RollbackableWorld {
		private var _frameRate:uint;
		private var _frameElapsed:Number;
		
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
		 * Children should override
		 * @param	c
		 */
		public function executeCommand(c:Command):void {
		}
		
		/**
		 * Update also handles updateLists
		 */
		override public function update():void {
			updateLists(); //update entities created by commands
			super.update();
			updateLists(); //update entities affected by collisions
		}
	}
}