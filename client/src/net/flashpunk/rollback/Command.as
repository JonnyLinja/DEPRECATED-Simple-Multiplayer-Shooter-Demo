package net.flashpunk.rollback {
	public class Command {
		//vars
		private var _player:Boolean;
		internal var _type:int;
		private var _frame:uint;
		private var _x:Number;
		private var _y:Number;
		
		//temp debugging
		public var executedFrame:uint;
		
		//linked list
		internal var next:Command=null;
		internal var prev:Command = null;
		
		public function Command(player:Boolean, command:int, frame:uint, x:Number=0, y:Number=0) {
			//check valid
			validateType(command);
			
			//save values
			_player = player;
			_type = command;
			_frame = frame;
			_x = x;
			_y = y;
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
		
		public function get player():Boolean {
			return _player;
		}
		
		public function get frame():uint {
			return _frame;
		}
		
		public function get x():Number {
			return _x;
		}
		
		public function get y():Number {
			return _y;
		}
	}
}