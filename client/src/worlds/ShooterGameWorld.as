package worlds {
	import rollback.engine.GameWorld;
	
	import net.flashpunk.FP;
	
	import rollback.commands.Command;
	
	import entities.Person;
	import entities.Alien;
	import entities.Human;
	
	import general.CommandList;
	
	//temp debugging
	import general.Utils;
	
	public class ShooterGameWorld extends GameWorld {
		//entities
		private var p1:Person = new Human(10, 10);
		private var p2:Person = new Alien(400, 400);
		
		public function ShooterGameWorld() {
			//super with frame rate 33
			super(33);
		}
		
		override public function begin():void {
			//super
			super.begin();
			
			//add entities
			add(p1);
			add(p2);
			
			//update
			updateLists();
		}
		
		override public function executeCommand(c:Command):void {
			//super
			super.executeCommand(c);
			
			//get correct player
			var p:Person;
			if (c.player)
				p = p1;
			else
				p = p2;
			
			//set mouse positions
			p.mouseX = c.x;
			p.mouseY = c.y;
			
			//move
			switch (c.type) {
				case CommandList.a:
					p.moveLeft = !p.moveLeft;
					break;
				case CommandList.d:
					p.moveRight = !p.moveRight;
					break;
				case CommandList.w:
					p.moveUp = !p.moveUp;
					break;
				case CommandList.s:
					p.moveDown = !p.moveDown;
					break;
				case CommandList.mouse:
					p.mouseDown = !p.mouseDown;
					//temp debugging
					//if (isTrueWorld)
						//Utils.log("true mouse is " + p.mouseDown);
					break;
			}
		}
	}
}