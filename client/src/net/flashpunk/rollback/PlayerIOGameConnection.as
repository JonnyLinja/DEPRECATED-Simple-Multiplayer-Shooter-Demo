package net.flashpunk.rollback {
	import playerio.Connection;
	import playerio.Message;
	
	import net.flashpunk.rollback.BlankCommand;
	import net.flashpunk.rollback.Command;
	import net.flashpunk.utils.Input;
	
	//temp debug
	import general.Utils;
	
	public class PlayerIOGameConnection extends GameConnection {
		//playerio variables
		private var conn:Connection;
		private var m:Message;
		private const MESSAGE_COMMANDS:String = "C";
		private const MESSAGE_FIGHT:String = "F";
		private const MESSAGE_SYNC_START_TIME:String = "S";
		private var isP1:Boolean; //which player you are, eventually will have player int inside responses for multiple players instead
		
		public function PlayerIOGameConnection(isP1:Boolean, conn:Connection) {
			//save variables
			this.isP1 = isP1;
			this.conn = conn;
			
			//handler
			conn.addMessageHandler(MESSAGE_FIGHT, fight);
			conn.addMessageHandler(MESSAGE_COMMANDS, receivedCommands);
			
			//super
			super();
		}
		
		private function fight(m:Message):void {
			//set mode
			syncingStartTime = false;
			
			//inform delegate
			receivedFightCommandCallback(m.getUInt(0) + firstTime);
			
			//temp debug
			var shit:uint = m.getUInt(0) + firstTime;
			Utils.log(shit + " = " + m.getUInt(0) + " + " + firstTime);
			
			//remove observer
			conn.removeMessageHandler(MESSAGE_FIGHT, fight);
		}
		
		override protected function sendStartSyncCommand():void {
			Utils.log("sending start sync command");
			m = conn.createMessage(MESSAGE_SYNC_START_TIME);
			conn.sendMessage(m);
			m = null;
		}
		
		override public function get hasOutgoing():Boolean {
			return (m != null);
		}
		
		override public function addOutgoingCommand(c:Command):void {
			//super
			super.addOutgoingCommand(c);
			
			//instantiate message and add frame/mouse
			if (!m) {
				//message
				m = conn.createMessage(MESSAGE_COMMANDS);
				
				//frame
				m.add(c.frame-lastMyFrame);
				lastMyFrame = c.frame;
				
				//mouse
				m.add(Input.mouseX);
				m.add(Input.mouseY);
			}
			
			//add command type to message
			m.add(c.type);
		}
		
		override public function sendCommands():void {
			//super
			super.sendCommands();
			
			//send
			if (m) {
				conn.sendMessage(m);
				m = null;
			}
		}
		
		private function receivedCommands(m:Message):void {
			//declare variables
			var commandArray:Vector.<Command> = new Vector.<Command>;
			var length:int = m.length;
			var cMouseX:int = m.getInt(1);
			var cMouseY:int = m.getInt(2);
			var c:int;
			
			//increment true max
			lastEnemyFrame += m.getUInt(0);
			
			//loop insert new command
			for (var pos:int = 3; pos < length; pos++) {
				c = m.getInt(pos);
				if (c == 0) {
					//blank
					commandArray.push(new BlankCommand(!isP1, lastEnemyFrame, cMouseX, cMouseY));
				}else {
					//normal
					commandArray.push(new Command(!isP1, c, lastEnemyFrame, cMouseX, cMouseY));
				}
			}
			
			//inform delegate
			receivedCommandsCallback(commandArray);
			
			//set null
			commandArray = null;
		}
		
		override public function terminate():void {
			//super
			super.terminate();
			
			//kill connection
			conn.removeMessageHandler(MESSAGE_COMMANDS, receivedCommands);
			conn.disconnect();
			conn = null;
		}
	}
}