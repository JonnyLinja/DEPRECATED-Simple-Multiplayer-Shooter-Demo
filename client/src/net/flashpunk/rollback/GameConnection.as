package net.flashpunk.rollback {
	import net.flashpunk.rollback.Command;
	import flash.utils.getTimer;
	
	public class GameConnection {
		//syncing start time variables
		public var receivedFightCommandCallback:Function;
		protected var syncingStartTime:Boolean = true;
		protected var firstTime:uint = 0;
		private var lastTime:uint = 0;
		private const sendRate:uint = 33;
		
		//gameplay variables
		public var receivedCommandsCallback:Function;
		protected var lastMyFrame:uint = 0; //last frame inputted by player
		protected var lastEnemyFrame:uint = 0; //last frame inputted by enemy player, eventually will be array for multiple players
		
		public function GameConnection() {
			//send command to server
			sendStartSyncCommand();
			
			//set time
			lastTime = getTimer();
			firstTime = lastTime;
		}
		
		/**
		 * Only called during sync start time
		 * Kinda hackish, consider having PlayWorld handle this and just provide function calls
		 */
		public function update():void {
			//only if sync start time
			if (!syncingStartTime)
				return;
			
			//get current time
			var currentTime:Number = getTimer();
			if (currentTime - lastTime >= sendRate) {
				//send command to server
				sendStartSyncCommand();
				
				//save time
				lastTime = currentTime;
			}
		}
		
		/**
		 * Only called during sync start time
		 * Children should implement
		 */
		protected function sendStartSyncCommand():void {
			
		}
		
		
		public function get lastFrameSent():uint {
			return lastMyFrame;
		}
		
		public function get lastFrameReceived():uint {
			return lastEnemyFrame;
		}
		
		public function get hasOutgoing():Boolean {
			return false;
		}
		
		public function addOutgoingCommand(c:Command):void {
			
		}
		
		public function sendCommands():void {
			
		}
		
		public function terminate():void {
			receivedCommandsCallback = null;
			receivedFightCommandCallback = null;
		}
	}
}