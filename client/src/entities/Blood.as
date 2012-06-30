package entities {
	import net.flashpunk.Rollbackable;
	
	import entities.SpriteMapEntity;
	
	public class Blood extends SpriteMapEntity {
		//sprite
		[Embed(source = '../../images/blood.PNG')]
		private static const image:Class;
		
		//size
		private const W:uint = 79;
		private const H:uint = 85;
		
		public function Blood(x:Number = 0, y:Number = 0) {
			//super
			super(x, y, image, W, H);
			
			//animations
			sprite_map.add("animate", [0, 1, 2], 10, false);
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
		}
	}
}