package worlds {
	import playerio.Connection;
	
	import rollback.engine.PlayWorld;
	import rollback.networking.PlayerIOGameConnection;
	import rollback.engine.GameWorld;
	
	import worlds.ShooterGameWorld;
	
	import net.flashpunk.utils.Key;
	import net.flashpunk.utils.Input;
	
	import general.CommandList;
	import general.Utils;
	
	public class ShooterPlayWorld extends PlayWorld {
		//helper
		private var lostWindowFocus:Boolean = false;
		
		//input command state
		private var space:Boolean = false; //temp debugging
		private var c:Boolean = false; //temp debugging
		private var w:Boolean = false;
		private var a:Boolean = false;
		private var s:Boolean = false;
		private var d:Boolean = false;
		private var mouse:Boolean = false;
		
		public function ShooterPlayWorld(isP1:Boolean, conn:Connection) {
			//super
			super(isP1, 2, 2, new PlayerIOGameConnection(isP1, conn));
		}
		
		/**
		 * Window focus
		 */
		override public function focusLost():void {
			Input.clear();
			lostWindowFocus = true;
		}
		
		override protected function createGameWorld():GameWorld {
			return new ShooterGameWorld();
		}
		
		override protected function updateInputs():void {
			if (lostWindowFocus) {
				//clicked out of window, reset!
				
				//left
				if (a) {
					a = false;
					addMyCommand(CommandList.a);
				}
				
				//right
				if (d) {
					d = false;
					addMyCommand(CommandList.d);
				}
				
				//up
				if (w) {
					w = false;
					addMyCommand(CommandList.w);
				}
				
				//down
				if (s) {
					s = false;
					addMyCommand(CommandList.s);
				}
				
				//mouse
				if (mouse) {
					mouse = false;
					addMyCommand(CommandList.mouse);
				}
				
				//c - temp debugging
				if (c) {
					c = false;
				}
				
				//space - temp debugging
				if (space) {
					space = false;
				}
				
				//reset
				lostWindowFocus = false;
			}else {
				//send player inputs!
				
				//left
				if(Input.check(Key.A) != a) {
					a = !a;
					addMyCommand(CommandList.a);
				}
				
				//right
				if(Input.check(Key.D) != d) {
					d = !d;
					addMyCommand(CommandList.d);
				}
				
				//up
				if(Input.check(Key.W) != w) {
					w = !w;
					addMyCommand(CommandList.w);
				}
				
				//down
				if(Input.check(Key.S) != s) {
					s = !s;
					addMyCommand(CommandList.s);
				}
				
				//mouse
				if (Input.mouseDown != mouse) {
					mouse = !mouse;
					addMyCommand(CommandList.mouse);
				}
				
				//c - temp debugging
				if (Input.check(Key.C) != c) {
					c = !c;
					if(c)
					Utils.log(displayCommands());
				}
				
				//space - temp debugging
				if (Input.check(Key.SPACE) != space) {
					space = !space;
					if(space)
					Utils.log(trueWorld.toString());
				}
			}
		}
	}
}