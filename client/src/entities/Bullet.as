package entities {
	import net.flashpunk.RollbackableSpriteMap;
	import net.flashpunk.Rollbackable;
	import net.flashpunk.FP;
	import net.flashpunk.RollbackableSfx;
	
	import entities.SpriteMapEntity;
	import entities.Person;
	import entities.Blood;
	
	import general.Utils;
	
	public class Bullet extends SpriteMapEntity {
		//sprite
		[Embed(source = '../../images/airball.PNG')]
		private static const image:Class;
		
		//sounds
		[Embed(source = '../../sounds/Airball.mp3')]
		private const SHOOT:Class;
		private var shoot:RollbackableSfx = new RollbackableSfx(SHOOT);
		
		//size
		private const W:uint = 14;
		private const H:uint = 12;
		
		//movement
		private static const speed:Number = 10;
		private var accelX:Number = 0;
		private var accelY:Number = 0;
		
		//collisions
		private static const COLLISION_TYPE:String = "bullet";
		
		public function Bullet(x:Number=0, y:Number=0) {
			//super
			super(x, y, image, W, H);
			
			//animations
			sprite_map.add("spin", [0, 1, 2, 4], 10, true);
			sprite_map.play("spin");
			
			//collision type
			type = COLLISION_TYPE;
			
			//sounds
			addSound(shoot);
		}
		
		override public function update():void {
			//super
			super.update();
			
			//collisions
			var p:Person = collide(Person.COLLISION_TYPE, x, y) as Person;
			if (p) {
				//hp
				p.hp--;
				
				//blood
				var blood:Blood = world.create(Blood, true) as Blood;
				blood.x = x - blood.halfWidth;
				blood.y = y - blood.halfHeight;
				
				//recycle
				world.recycle(this);
			}

			
			//go!
			x += accelX;
			y += accelY;
			
			//kill if offscreen
			if (x < 0 || y < 0 || x + width > FP.width || y + height > FP.height)
				world.recycle(this);
		}
		
		public function calculateVector(x:Number, y:Number):void {
			//basic vector
			accelX = x - centerX;
			accelY = y - centerY;
			
			//calculate ratio
			var magnitude:Number = Utils.distance(accelX , accelY, 0, 0);
			var ratio:Number = speed / magnitude;
			
			//apply ratio
			accelX *= ratio;
			accelY *= ratio;
		}
		
		override public function added():void {
			//super
			super.added();
			
			//ugly hack to prevent it from hitting yourself
			x += (accelX*4);
			y += (accelY * 4);
			
			//sound
			shoot.play();
		}
		
		override public function rollback(orig:Rollbackable):void {
			//super
			super.rollback(orig);
			
			//cast
			var b:Bullet = orig as Bullet;
			
			//rollback
			accelX = b.accelX;
			accelY = b.accelY;
		}
	}
}