package entities {
	import net.flashpunk.Rollbackable;
	
	import entities.SpriteMapEntity;
	
	public class Blood extends SpriteMapEntity {
		//sprite
		[Embed(source = '../../images/blood_small.jpg')]
		private static const image:Class;
		
		//size
		private const W:uint = 25;
		private const H:uint = 25;
		
		public function Blood(x:Number=0, y:Number=0) {
			//super
			super(x, y, image, W, H);
			
			//animations
			//sprite_map.add("animate", [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], 10, false);
		}
		
		override public function update():void {
			//super
			super.update();
			
			//recycle
			//if (sprite_map.currentAnim == null || sprite_map.currentAnim == "")
				//world.recycle(this);
		}
		
		override public function added():void {
			//super
			super.added();
			
			//play
			//sprite_map.play("animate");
		}
	}
}