package rollback.engine {
	import rollback.commands.Command;	
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
		
		override public function update():void {
			updateLists();
			super.update();
			updateLists();
		}
	}
}