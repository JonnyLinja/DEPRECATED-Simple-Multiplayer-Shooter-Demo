package entities {
	import entities.Person;
	
	public class Alien extends Person {
		//sprite
		[Embed(source = '../../images/aliengun.png')]
		private static const image:Class;
		
		//size
		private const W:uint = 31;
		private const H:uint = 33;

		public function Alien(x:Number = 0, y:Number = 0) {
			//super
			super(x, y, image, W, H);
		}
	}
}