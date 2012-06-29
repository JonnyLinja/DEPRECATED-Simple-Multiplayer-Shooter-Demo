package rollback.commands {
	public class BlankCommand extends Command {
		public function BlankCommand(player:Boolean, frame:uint, x:Number, y:Number) {
			//super
			super(player, 1, frame, x, y);
			
			//override type to blank
			_type = 0;
		}
	}
}