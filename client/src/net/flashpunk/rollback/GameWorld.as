package net.flashpunk.rollback {
	import net.flashpunk.rollback.Command;	
	import net.flashpunk.RollbackableWorld;
	import net.flashpunk.Rollbackable;
	
	public class GameWorld extends RollbackableWorld {
		public function GameWorld(frameRate:uint) {
			//super
			super(frameRate);
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
		}
	}
}