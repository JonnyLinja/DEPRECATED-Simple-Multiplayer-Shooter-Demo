package rollback.commands {
	public class Command {
		//vars
		public var player:Boolean;
		protected var _type:int;
		public var frame:uint;
		public var x:Number;
		public var y:Number;
		
		//temp debugging
		public var executedFrame:uint;
		
		//linked list
		public var next:Command=null;
		public var prev:Command=null;
		
		public function Command(player:Boolean, command:int, frame:uint, x:Number=0, y:Number=0) {
			//check valid
			validateType(command);
			
			//save values
			this.player = player;
			_type = command;
			this.frame = frame;
			this.x = x;
			this.y = y;
		}
		
		private function validateType(type:int):void {
			//error checking
			if (type == 0)
				throw new Error("0 is reserved type for Command");
		}
		
		public function get type():int {
			return _type;
		}
		
		public function set type(type:int):void {
			//check valid
			validateType(type);
			
			//save it
			_type = type;
		}
	}
}