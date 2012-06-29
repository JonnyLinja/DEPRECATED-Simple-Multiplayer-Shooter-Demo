package entities {
	import net.flashpunk.RollbackableSpriteMap;
	import net.flashpunk.Rollbackable;
	import net.flashpunk.FP;
	
	import entities.SpriteMapEntity;
	import entities.Person;
	import entities.Blood;
	
	import general.Utils;
	
	//temp debug
	import net.flashpunk.Entity;
	import flash.geom.Point;
	
	public class Bullet extends SpriteMapEntity {
		//sprite
		[Embed(source = '../../images/airball.PNG')]
		private static const image:Class;
		
		//size
		private const W:uint = 14;
		private const H:uint = 12;
		
		//movement
		private static const speed:Number = 10;
		private var accelX:Number = 0;
		private var accelY:Number = 0;
		
		//collisions
		private static const COLLISION_TYPE:String = "bullet";
		
		//should
		private var shouldDie:Boolean = false;
		
		public function Bullet(x:Number=0, y:Number=0) {
			//super
			super(x, y, image, W, H);
			
			//animations
			sprite_map.add("spin", [0, 1, 2, 4], 10, true);
			sprite_map.play("spin");
			
			//collision type
			type = COLLISION_TYPE;
		}
		
		override public function resetShouldVariables():void {
			//super
			super.resetShouldVariables();
			
			//reset should
			shouldDie = false;
		}
		
		override public function determineShouldVariablesBasedOnCollision():void {
			//super
			super.determineShouldVariablesBasedOnCollision();
			
			//collide
			if (collide(Person.COLLISION_TYPE, x, y))
				shouldDie = true;
			
			//temp debug
			checkCollide(COLLISION_TYPE, false, didCollideWithBullet);
		}
		
		public function didCollideWithBullet(e:Entity, hitTestResult:int, intersectSize:Point):void {
			var b:Bullet = e as Bullet;
			if (b == this)
				return;
			if (centerX == b.centerX && centerY == b.centerY)
				Utils.log("bullet stacking");
		}
		
		override public function resolveShouldVariables():void {
			//super
			super.resolveShouldVariables();
			
			if (shouldDie) {
				var blood:Blood = world.create(Blood, true) as Blood;
				//var blood:Blood = new Blood();
				//world.add(blood);
				blood.x = x + blood.halfWidth;
				blood.y = y + blood.halfHeight;
				
				//world.recycle(this);
			}
		}
		
		override public function update():void {
			//super
			super.update();
			
			//temp debug
			if (sprite_map.currentAnim != "spin")
				Utils.log("omg y is it not spinning?");
			if (!world)
				Utils.log("null world but still updating?");
			
			//go!
			x += accelX;
			y += accelY;
			
			//kill if offscreen
			if (x < 0 || y < 0 || x + width > FP.width || y + height > FP.height) {
				world.recycle(this);
				
				//temp debugging
				if (isTrueEntity)
					Utils.log("recycled bullet");
			}
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
		
		override public function rollback(orig:Rollbackable):void {
			//super
			super.rollback(orig);
			
			//temp debug
			//if (isTrueEntity)
				//Utils.log("reverse rollback bullet");
			
			//cast
			var b:Bullet = orig as Bullet;
			
			//rollback
			accelX = b.accelX;
			accelY = b.accelY;
		}
	}
}