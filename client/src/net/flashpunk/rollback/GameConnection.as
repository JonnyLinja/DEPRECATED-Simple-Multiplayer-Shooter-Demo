package net.flashpunk.rollback {
	import net.flashpunk.rollback.Command;
	
	public class GameConnection {
		public var callback:Function;
		protected var lastMyFrame:uint = 0; //last frame inputted by player
		protected var lastEnemyFrame:uint = 0; //last frame inputted by enemy player, eventually will be array for multiple players
		
		public function GameConnection() {
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
			
		}
	}
}