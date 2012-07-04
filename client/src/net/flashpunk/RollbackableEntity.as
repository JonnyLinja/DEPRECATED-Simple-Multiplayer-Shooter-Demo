package net.flashpunk {
	import flash.geom.Point;
	
	import net.flashpunk.Entity;
	import net.flashpunk.RollbackableSfx;
	import net.flashpunk.RollbackableWorld;
	import net.flashpunk.namespace.RollbackNamespace;
	
	use namespace RollbackNamespace;
	
	public class RollbackableEntity extends Entity implements Rollbackable {
		/**
		 * Boolean indicating if entity exists in true or perceived world
		 */
		RollbackNamespace var _isTrueEntity:Boolean=false;
		
		/**
		 * Collision did not occur
		 */
		public const HIT_NONE:int = 0;
		
		/**
		 * Collided along the top side
		 */
		public const HIT_TOP:int = 1;
		
		/**
		 * Collided along the bottom side
		 */
		public const HIT_BOTTOM:int = 2;
		
		/**
		 * Collided along the left side
		 */
		public const HIT_LEFT:int = 3;
		
		/**
		 * Collided along the right side
		 */
		public const HIT_RIGHT:int = 4;
		
		public function RollbackableEntity(x:Number = 0, y:Number = 0) {
			super(x, y);
		}
		
		public function get isTrueEntity():Boolean {
			return _isTrueEntity;
		}
		
		/**
		 * Checks for collisions against a type
		 * Calls callback with entity and the hitTest
		 * @param	type
		 * @param	callback
		 * @param	preventOverlap
		 */
		public function checkCollide(type:String, preventOverlap:Boolean = false, callback:Function = null):void {
			//declare variables
			var collisionList:Vector.<Entity> = new Vector.<Entity>();
			var intersect:Point = null;
			var hitTest:int = 0;
			
			//populate vector
			collideInto(type, x, y, collisionList);
			
			//loop through vector
			for each (var e:Entity in collisionList) {
				//intersection and hittest
				intersect = getIntersectRect(e);
				hitTest = this.hitTest(e, preventOverlap, intersect);
				
				//callback
				if(callback != null)
					callback(e, hitTest, intersect);
			}
		}
		
		/**
		 * Returns which side was hit
		 * Assumes that the two Entites DO ALREADY COLLIDE
		 * Sets shouldMoveX and shouldMoveY if preventOverlap is true
		 * @param	e
		 * @param	preventOverlap
		 * @return
		 */
		public function hitTest(e:Entity, preventOverlap:Boolean=false, intersect:Point=null):int {
			if (!intersect)
				intersect = getIntersectRect(e);
			
			/*
			//ratio - may not need, might be able to fudge with 1-1 ratio
			//right now set to use bigger of the two
			//could set to use smaller no problem
			var ratioX:int;
			var ratioY:int;
			if (width * height > e.width * e.height) {
				ratioX = width;
				ratioY = height;
			}else {
				ratioX = e.width;
				ratioY = e.height;
			}
			*/
			
			var ratioX:int = 1;
			var ratioY:int = 1;
			
			//Didn't divide by 2 overlap, but still seems to work? wtf?
			//It should move too far away...but it's working somehow
			//Leaving it for now! If it's a problem fix it later!
			
			//exclude
			if ((intersect.x / ratioY) <= (intersect.y / ratioX)) {
				//horizontal
				if (x < e.x) {
					//left
					if(preventOverlap)
						x -= intersect.x;
					return HIT_RIGHT;
				}else {
					//right
					if(preventOverlap)
						x += intersect.x;
					return HIT_LEFT;
				}
			}else {
				//vertical
				if (y < e.y) {
					//up
					if(preventOverlap)
						y -= intersect.y;
					return HIT_BOTTOM;
				}else {
					//down
					if(preventOverlap)
						y += intersect.y;
					return HIT_TOP;
				}
			}
		}
		
		/**
		 * Returns point with the size of the intersecting collision rectangle
		 * @param	e
		 * @return
		 */
		protected function getIntersectRect(e:Entity):Point {
			//declare variables
			var intersectionWidth:Number = 0;
			var intersectionHeight:Number = 0;
			
			//horizontal
			if (x < e.x)
				intersectionWidth = Math.abs(x + width - e.x);
			else if (e.x != x)
				intersectionWidth = Math.abs(e.x + e.width - x);
			else
				intersectionWidth = Math.min(width, e.width);
			
			//vertical
			if (y < e.y)
				intersectionHeight = Math.abs(y + height - e.y);
			else if (e.y != y)
				intersectionHeight = Math.abs(e.y + e.height - y);
			else
				intersectionHeight = Math.min(height, e.height);
			
			//return point
			return new Point(intersectionWidth, intersectionHeight);
		}
		
		/**
		 * Adds sounds to be played/rolled back as needed
		 * @param	s
		 */
		public function addSound(s:RollbackableSfx):void {
			//connect
			if (_firstSfx)
				s.next = _firstSfx;
			
			//set it as head
			_firstSfx = s;
			
			//set frame getter
			s.getStartFrame = getFrame;
		}
		
		//frame getter
		private function getFrame():Number {
			return (world as RollbackableWorld).frame;
		}
		
		override public function render():void {
			//super
			super.render();
			
			//deciare variables
			var w:RollbackableWorld = world as RollbackableWorld;
			
			//sounds
			var current:RollbackableSfx = _firstSfx;
			while (current) {
				//play, note frame-1 is to offset frame increment in update
				current.render(w.frame-1, w.frameRate);
				
				//increment
				current = current.next;
			}
		}
		
		/**
		 * Rolls back primitive values of current Entity to oldEntity
		 * @param	oldEntity	entity to be rolled back to
		 */
		public function rollback(orig:Rollbackable):void {
			//declare variables
			var e:RollbackableEntity = orig as RollbackableEntity;
			
			//priority
			_updatePriority = e._updatePriority;
			_typePriority = e._typePriority;
			
			//position
			x = e.x;
			y = e.y;
			
			//visibility
			visible = e.visible;
			
			//active
			active = e.active;
			
			//type
			type = e.type;
			
			//sounds
			var current:RollbackableSfx = _firstSfx;
			var eCurrent:RollbackableSfx = e._firstSfx;
			while (current && eCurrent) {
				//rollback
				current.rollback(eCurrent);
				
				//increment
				current = current.next;
				eCurrent = eCurrent.next;
			}
		}
		
		/**
		 * temp debug
		 * @return
		 */
		override public function toString():String {
			return this.getClass() + "\t" + (this.world != null) + "\t" + x + ", " + y;
		}
		
		/** @private */ private var _firstSfx:RollbackableSfx = null;
		/** @private */ internal var _updatePriority:int = 0; //to ensure that perceived and true worlds update entities in the same order
		/** @private */ internal var _typePriority:int = 0; //to ensure that perceived and true worlds check collisions in the same order
		/** @private */ internal var _created:Boolean; //to determine if should add to the master list
		/** @private */ internal var _next:RollbackableEntity; //master list
		/** @private */ internal var _recyclePrev:RollbackableEntity; //doubly linked recycle
	}
}