package rollback.engine {
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import net.flashpunk.World;
	import net.flashpunk.FP;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	
	import rollback.commands.Command;
	import rollback.commands.BlankCommand;
	import rollback.engine.GameWorld;
	import rollback.networking.GameConnection;
	
	//temp debug
	import general.Utils;
	
	public class PlayWorld extends World {
		//worlds
		private var perceivedWorld:GameWorld;
		protected var trueWorld:GameWorld; //temp protected
		
		//command datastructure
		private var firstCommand:Command; //first in linked list
		private var lastCommand:Command; //last in linked list
		private var trueCommand:Command; //last executed true command
		private var perceivedCommand:Command; //last executed perceived command
		
		//frames
		private var frameDelay:uint = 3; //how many frames to delay inputs by - has to be at least 1!
		private var frameMinSend:uint = 10; //tries sends mouse position - was set to 10!
		private var trueFrame:uint = 0; //current frame of true - can eventually be GameWorld variable
		private var perceivedFrame:uint = 0; //current frame of perceived - can eventually be GameWorld varaible
		
		//time
		private var currentTime:uint = 0;
		private var nextFrameTime:uint = 0; //for perceived
		
		//game loop
		private var perceivedUpdateCount:int; //number of times perceived was updated during this frame
		
		//connection
		private var conn:GameConnection;
		
		//boolean checks
		private var isP1:Boolean; //eventually be able to handle more than 2 players, no longer boolean then
		private var shouldRender:Boolean = true;
		
		//temp debug
		private var trueMouse:Boolean = false;
		
		public function PlayWorld(isP1:Boolean, frameDelay:uint, frameMinSend:uint, conn:GameConnection) {
			//set variables
			this.isP1 = isP1;
			this.frameDelay = frameDelay + 1;
			this.frameMinSend = frameMinSend;
			this.conn = conn;
			nextFrameTime = getTimer();
			
			//factory worlds
			perceivedWorld = createGameWorld();
			trueWorld = createGameWorld();
			trueWorld.isTrueWorld = true;
			
			//game worlds
			trueWorld.begin();
			perceivedWorld.begin();
			
			//sync point
			trueWorld.beginSync();
			perceivedWorld.beginSync();
			
			//set delegate
			conn.callback = receivedCommands;
		}
		
		/**
		 * Children must override
		 * Factory method
		 * @return
		 */
		protected function createGameWorld():GameWorld {
			return null;
		}
		
		/**
		 * Children should override
		 * Hook
		 * @param	frame
		 */
		protected function updateInputs():void {
			
		}
		
		/**
		 * Children should use this to send commands in their updateInputs function
		 * Eventually modified to allow sending of mouse positions or not
		 * Eventually modified to allow more than 2 players
		 * @param	commandType
		 */
		protected function addMyCommand(commandType:int):void {
			//temp debugging
			if (perceivedUpdateCount <= 0)
				Utils.log("adding my dupe command");
			
			addMyCommandPrivate(new BlankCommand(isP1, perceivedFrame + frameDelay, Input.mouseX, Input.mouseY));
			addMyCommandPrivate(new Command(isP1, commandType, perceivedFrame + frameDelay, Input.mouseX, Input.mouseY));
		}
		
		/**
		 * Convenience function to see command list
		 * @return
		 */
		public function displayCommands():String {
			var result:String = "====================FRAMES====================\n";
			result += "true: " + trueFrame + "\nperceived:" + perceivedFrame + "\n";
			
			result += "====================COMMANDS====================\n";
			result += "frame\t\texe frametype\tplayer\tx\ty\n"
			
			//declare variables
			var cmd:Command = firstCommand;
			
			while (cmd) {
				//print
				result += cmd.frame + "\t" + cmd.executedFrame + "\t" + cmd.type + "\t" + cmd.player + "\t" + cmd.x + "\t" + cmd.y + "\n";
				if (cmd == trueCommand)
					result += "\ttrue\n";
				if (cmd == perceivedCommand)
					result += "\tperceived\n";
				if (cmd.prev && (cmd.prev).next != cmd)
					result += "\tstructure error, prev.next != self\n";
				if (cmd.next && (cmd.next).prev != cmd)
					result += "\tstructure error, next.prev != self\n";
				
				//increment
				cmd = cmd.next;
			}
			
			return result;
		}
		
		/**
		 * Inserts to the command linked list with a linear search from end
		 * @param	c
		 */
		private function insertCommand(c:Command):void {
			//declare vars
			var current:Command = lastCommand;
			
			//insertion
			if (current) {
				//add to existing
				
				//search for position based on frames
				while (c.frame < current.frame) {
					current = current.prev;
					if (!current)
						break;
				}
				
				//connect linked list
				if (current) {
					//add normally
					c.prev = current;
					c.next = current.next;
					if (c.next) {
						//not last command
						(c.next).prev = c;
					}else {
						//last one, reset last command
						lastCommand = c;
					}
					current.next = c;
				}else {
					//is at beginning of list - should never happen but just in case
					c.next = firstCommand;
					firstCommand.prev = c;
					firstCommand = c;
				}
			}else {
				//is first command
				lastCommand = c;
				firstCommand = c;
			}
		}
		
		/**
		 * Inserts current player command
		 * Prepares to send command to other players
		 * Used for current player commands only, not received ones
		 * @param	c
		 */
		private function addMyCommandPrivate(c:Command):void {
			//insert command
			insertCommand(c);
			
			//add to outgoing
			conn.addOutgoingCommand(c);
		}
		
		/**
		 * Inserts received commands
		 * Delegate function of GameConnection
		 * @param	commands
		 */
		private function receivedCommands(commands:Vector.<Command>):void {
			//loop through commands
			for each (var c:Command in commands) {
				//insert
				insertCommand(c);
			}
		}
		
		/**
		 * Updates true, perceived, and inputs
		 */
		override public function update():void {
			//super
			super.update();
			
			//set current time
			currentTime = getTimer();
			
			//set elapsed
			FP.elapsed = trueWorld.frameElapsed;
			
			//updates
			updateTrueWorld();
			updatePerceivedWorld();
			updateInputsPrivate();
		}
		
		/**
		 * Updates the true world if able
		 * If able, performs rollback on the perceived world
		 */
		private function updateTrueWorld():void {
			//determine frame to loop to
			var leastFrame:Number = Math.min(conn.lastFrameReceived, perceivedFrame-1); //eventually update this to accept multiple players
			
			//synchronize
			if(trueFrame <= leastFrame)
				trueWorld.synchronize(perceivedWorld);
			else
				return;
			
			//declare variables
			var shouldRollback:Boolean = false;
			var commandToCheck:Command;
			
			//loop update true
			do {
				//commands
				if (firstCommand) {
					//at least 1 command!, loop through them
					while (true) {
						//set command to check
						if (!trueCommand)
							//never executed command before, check against firstCommand
							commandToCheck = firstCommand;
						else
							//executed command before, check against nextCommand
							commandToCheck = trueCommand.next;
						
						//should execute command check
						if (!commandToCheck || commandToCheck.frame != trueFrame)
							break;
						
						//should rollback
						shouldRollback = true;
						
						//execute command
						trueWorld.executeCommand(commandToCheck);
						
						//temp debugging
						commandToCheck.executedFrame = trueFrame;
						/*
						if (commandToCheck.type == 5) {
							trueMouse = !trueMouse;
							Utils.log("true should be " + trueMouse);
						}
						*/
						
						//increment true command
						trueCommand = commandToCheck;
					}
				}
				
				//update true world
				trueWorld.update();
				
				//increment true frame
				trueFrame++;
				
				//temp debug
				Utils.log("true " + trueFrame);
			}while (trueFrame <= leastFrame);
			
			//should rollback
			//if (!shouldRollback) //temp debug - shoudln't need to do the following
				//return;			//temp debug
			
			//rollback
			perceivedWorld.synchronize(trueWorld);
			perceivedWorld.rollback(trueWorld);
			perceivedCommand = trueCommand;
			
			//loop update perceived
			Utils.log("fast forward, from true " + trueFrame + " to " + perceivedFrame); //temp debug
			for (var tempFrame:int = trueFrame; tempFrame < perceivedFrame; tempFrame++ ) {
				//commands
				if (firstCommand) {
					//at least 1 command!, loop through them
					while (true) {
						//set command to check
						if (!perceivedCommand)
							//never executed command before, check against firstCommand
							commandToCheck = firstCommand;
						else
							//executed command before, check against nextCommand
							commandToCheck = perceivedCommand.next;
						
						//should execute command check
						if (!commandToCheck || commandToCheck.frame != tempFrame)
							break;
						
						//execute command
						perceivedWorld.executeCommand(commandToCheck);
						
						//increment perceived command
						perceivedCommand = commandToCheck;
					}
				}
				
				//update perceived world
				perceivedWorld.update();
				
				//temp debug
				Utils.log("perceived fastforward " + ((int)(tempFrame+1)));
			}
		}
		
		/**
		 * Updates the perceived world if able
		 * If able, sends message to server
		 */
		private function updatePerceivedWorld():void {
			//should render
			if (currentTime >= nextFrameTime)
				shouldRender = true;
			else
				return;
			
			//reset count
			perceivedUpdateCount = 0;
			
			//declare variables
			var commandToCheck:Command;
			
			//loop update perceived
			do {
				//commands
				if (firstCommand) {
					//at least 1 command!, loop through them
					while (true) {
						//set command to check
						if (!perceivedCommand) {
							//never executed command before, check against firstCommand
							commandToCheck = firstCommand;
						}else
							//executed command before, check against nextCommand
							commandToCheck = perceivedCommand.next;
						
						//should execute command check
						if (!commandToCheck || commandToCheck.frame != perceivedFrame)
							break;
						
						//execute command
						perceivedWorld.executeCommand(commandToCheck);
						
						//increment perceived command
						perceivedCommand = commandToCheck;
					}
				}
				
				//update perceived world
				perceivedWorld.update();
				
				//increment perceived frame
				perceivedFrame++;
				
				//temp debug
				Utils.log("perceived " + perceivedFrame);
				
				//increment count
				perceivedUpdateCount++;
				
				//increment next frame
				nextFrameTime += perceivedWorld.frameRate;
			}while (currentTime >= nextFrameTime);
		}
		
		/**
		 * Adds to current command list
		 * Adds new commands to the message to be sent
		 */
		private function updateInputsPrivate():void {
			//determine is should run
			if (!shouldRender)
				return;
			
			//template power
			updateInputs();
			
			var toSendFrame:Number = perceivedFrame + frameDelay;
			
			//blank commands
			//temp debug
			/*
			if (!conn.hasOutgoing) {
				if (conn.lastFrameSent + frameMinSend < toSendFrame) {
					addMyCommandPrivate(new BlankCommand(isP1, toSendFrame, Input.mouseX, Input.mouseY));
				}
			}
			*/
			
			//send message
			conn.sendCommands();
		}
		
		/**
		 * Renders the perceived world
		 */
		override public function render():void {
			if (shouldRender)
				//perceivedWorld.render();
			shouldRender = false;
			
			//temp debug
			trueWorld.render();
		}
		
		/**
		 * Destroys the command linked list and the two worlds upon finishing
		 */
		override public function end():void {
			//super
			super.end();
			
			//game worlds
			trueWorld.end();
			perceivedWorld.end();
			
			//connection
			conn.terminate();
		}
	}
}