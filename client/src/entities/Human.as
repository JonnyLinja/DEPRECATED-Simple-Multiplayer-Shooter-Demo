package entities {
	import entities.Person;
	
	public class Human extends Person {
		//sprite
		[Embed(source = '../../images/humangun.png')]
		private static const image:Class;
		
		//size
		private const W:uint = 34;
		private const H:uint = 33;

		public function Human(x:Number = 0, y:Number = 0) {
			//super
			super(x, y, image, W, H);
			
			//tint color
			sprite_map.color = 0xFF0000;
		}
	}
}