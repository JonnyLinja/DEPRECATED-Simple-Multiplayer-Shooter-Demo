package entities {
	import net.flashpunk.Rollbackable;
	import net.flashpunk.RollbackableSfx;
	
	import entities.SpriteMapEntity;
	
	public class Blood extends SpriteMapEntity {
		//sprite
		[Embed(source = '../../images/blood.PNG')]
		private static const image:Class;
		
		//sounds
		[Embed(source = '../../sounds/BoulderDeath.mp3')]
		private static const BOOM:Class;
		private var boom:RollbackableSfx = new RollbackableSfx(BOOM);
		
		//size
		private const W:uint = 79;
		private const H:uint = 85;
		
		public function Blood(x:Number = 0, y:Number = 0) {
			//super
			super(x, y, image, W, H);
			
			//animations
			sprite_map.add("animate", [0, 1, 2], 10, false);
			
			//sounds
			addSound(boom);
		}
		
		override public function update():void {
			//super
			super.update();
			
			//recycle
			if (sprite_map.complete)
				world.recycle(this);
		}
		
		override public function added():void {
			//super
			super.added();
			
			//play
			sprite_map.play("animate", true, 0);
			boom.play();
		}
		
		override public function destroy():void {
			//super
			super.destroy();
			
			//sfx
			boom.stop();
			boom = null;
		}
	}
}