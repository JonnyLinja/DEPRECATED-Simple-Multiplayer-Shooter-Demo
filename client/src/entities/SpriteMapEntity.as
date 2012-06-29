package entities {
	import net.flashpunk.RollbackableSpriteMap;
	import net.flashpunk.RollbackableEntity;
	import net.flashpunk.Rollbackable;
	
	public class SpriteMapEntity extends RollbackableEntity {
		//sprite map
		protected var sprite_map:RollbackableSpriteMap;

		public function SpriteMapEntity(x:Number = 0, y:Number = 0, image:Class = null, w:uint = 0, h:uint = 0) {
			//super
			super(x, y);
			
			//image
			if (image) {
				//sprite
				sprite_map = new RollbackableSpriteMap(image, w, h);
				graphic = sprite_map;
			}
			
			//size
			width = w;
			height = h;
		}
		
		override public function rollback(orig:Rollbackable):void {
			//super
			super.rollback(orig);
			
			//cast
			var s:SpriteMapEntity = orig as SpriteMapEntity;
			
			//roll back
			sprite_map.rollback(s.sprite_map);
		}
	}
}