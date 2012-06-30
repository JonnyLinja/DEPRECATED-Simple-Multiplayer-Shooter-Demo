package net.flashpunk {
	import net.flashpunk.World;
	import net.flashpunk.Entity;
	import net.flashpunk.FP;
	
	import flash.utils.Dictionary;
	
	public class RollbackableWorld extends World implements Rollbackable {
		/**
		 * Boolean indicating if world is true or perceived world
		 */
		public var isTrueWorld:Boolean = false;
		
		public function RollbackableWorld() {
			
		}
		
		/**
		 * Modified to set isTrueEntity
		 * @param	e
		 * @return
		 */
		override public function add(e:Entity):Entity {
			//cast
			var r:RollbackableEntity = e as RollbackableEntity;
			
			//set is true
			r.isTrueEntity = isTrueWorld;
			
			//super
			return super.add(r);
		}
		
		/**
		 * Modified to use private _recycled variable
		 * Modified to accomodate doubly linked recycle list
		 * Modified to set isTrueEntity
		 */
		override public function create(classType:Class, addToWorld:Boolean = true):Entity {
			var e:RollbackableEntity = _recycled[classType] as RollbackableEntity;
			if (e) {
				if(e._recycleNext)
					(e._recycleNext as RollbackableEntity)._recyclePrev = null;
				_recycled[classType] = e._recycleNext;
				e._recycleNext = null;
			}
			else e = new classType;
			e.isTrueEntity = isTrueWorld;
			
			// return
			if (addToWorld) return add(e);
			return e;
		}
		
		/**
		 * Returns the unrecycled Entity.
		 * @param	e				The Entity to unrecycle.
		 * @param	addToWorld		Add it to the World immediately.
		 * @return	The Entity object.
		 */
		public function unrecycle(e:RollbackableEntity, addToWorld:Boolean = true):Entity {
			//connect the surrounding elements
			if(e._recycleNext)
				(e._recycleNext as RollbackableEntity)._recyclePrev = e._recyclePrev;
			if(e._recyclePrev)
				(e._recyclePrev as RollbackableEntity)._recycleNext = e._recycleNext;
			
			//move head
			if (e == _recycled[e._class])
				_recycled[e._class] = e._recycleNext;
			
			//make connects null
			e._recyclePrev = null;
			e._recycleNext = null;
			
			if (addToWorld) return add(e);
				return e;
		}
		
		/**
		 * Modified to add to master list and add unrecycled entities
		 */
		override public function updateLists():void {
			var e:RollbackableEntity;
			
			// remove entities
			if (_remove.length) {
				for each (e in _remove) {
					if (!e._world) {
						if(_add.indexOf(e) >= 0)
							_add.splice(_add.indexOf(e), 1);
						
						continue;
					}
					if (e._world !== this)
						continue;
					
					e.removed();
					e._world = null;
					
					removeUpdate(e);
					removeRender(e);
					if (e._type) removeType(e);
					if (e._name) unregisterName(e);
					if (e.autoClear && e._tween) e.clearTweens();
				}
				_remove.length = 0;
			}
			
			// add entities
			if (_add.length) {
				
				//helper
				var callAdded:Boolean = false;
				var r:RollbackableEntity = null;
				
				for each (e in _add) {
					//add to master list
					if (!e._created) {
						e._created = true;
						addToMasterList(e);
					}
					
					//add brand new Entity to recycled list
					if (e._world) {
						e._world = null;
						e._recyclePrev = null;
						e._recycleNext = null;
						if (e.autoClear && e._tween) e.clearTweens();
						_recycle[_recycle.length] = e;
						continue;
					}
					
					//set world
					e._world = this;
					
					//set callAdded if is not a unrecycle
					r = e as RollbackableEntity;
					callAdded = (r._typePriority == 0 || r._updatePriority == 0);
					
					//add to update and render
					addUpdate(e);
					addRender(e);
					if (e._type) addType(e);
					if (e._name) registerName(e);
					
					//call added
					if(callAdded)
						e.added();
				}
				//set length
				_add.length = 0;
			}
			
			// recycle entities
			if (_recycle.length) {
				for each (e in _recycle) {
					if (e._world || e._recycleNext || e._recyclePrev)
						continue;
					
					e._recycleNext = _recycled[e._class];
					if(e._recycleNext)
						(e._recycleNext as RollbackableEntity)._recyclePrev = e;
					_recycled[e._class] = e;
				}
				_recycle.length = 0;
			}
			
			// sort the depth list
			if (_layerSort) {
				if (_layerList.length > 1) FP.sort(_layerList, true);
				_layerSort = false;
			}
		}
		
		/** @private Adds Entity to the master list. */
		private function addToMasterList(e:RollbackableEntity):void {
			// add to master list
			if (_lastEntity) {
				//not first entry into list
				_lastEntity._next = e;
				_lastEntity = e;
			}else {
				//first entry
				_firstEntity = e;
				_lastEntity = e;
			}
			
			//cleanup
			e._next = null;
		}
		
		/**
		 * Modified to ensure update order
		 * @param	e
		 */
		override protected function addUpdate(e:Entity):void {
			//cast
			var r:RollbackableEntity = e as RollbackableEntity;
			
			if (!_updateFirst) {
				//no head
				
				//set priority
				r._updatePriority = 1;
				
				//connect
				r._updatePrev = null;
				r._updateNext = null;
				
				//set head
				_updateFirst = r;
			}else {
				//has head
				
				//declare variables
				var current:RollbackableEntity = _updateFirst as RollbackableEntity;
				var last:RollbackableEntity = null;
				
				//set initial update priority
				if (r._updatePriority == 0)
					r._updatePriority = current._updatePriority + 1;
				
				//loop
				while (current) {
					//found position
					if (r._updatePriority > current._updatePriority)
						break;
					
					//increment
					last = current;
					current = current._updateNext as RollbackableEntity;
				}
				
				//insert
				if(!current) {
					//end of list
					
					//connect
					last._updateNext = r;
					r._updatePrev = last;
					r._updateNext = null;
				}else {
					//insert here
					
					//connect
					r._updateNext = current;
					if (current == _updateFirst) {
						//is the head
						_updateFirst = r;
						r._updatePrev = null;
					}else {
						//not the head
						r._updatePrev = current._updatePrev;
						r._updatePrev._updateNext = r;
					}
					current._updatePrev = r;
				}
			}
			
			//increment variables
			_count ++;
			if (!_classCount[e._class])
				_classCount[e._class] = 0;
			_classCount[e._class] ++;
		}
		
		/**
		 * Modified to ensure update order
		 * @param	e
		 */
		override protected function removeUpdate(e:Entity):void {
			//reset priority
			var r:RollbackableEntity = e as RollbackableEntity;
			r._updatePriority = 0;
			
			//super
			super.removeUpdate(r);
		}
		
		/**
		 * Modified to ensure type order
		 * @param	e
		 */
		override internal function addType(e:Entity):void {
			//cast
			var r:RollbackableEntity = e as RollbackableEntity;
			
			if (!_typeFirst[e._type]) {
				//no head
				
				//set priority
				r._typePriority = 1;
				
				//connect
				r._typePrev = null;
				r._typeNext = null;
				
				//set head
				_typeFirst[e._type] = r;
				
				//increment
				_typeCount[e._type] = 1;
			}else {
				//has head
				
				//declare variables
				var current:RollbackableEntity = _typeFirst[e._type] as RollbackableEntity;
				var last:RollbackableEntity = null;
				
				//set initial update priority
				if (r._typePriority == 0)
					r._typePriority = current._typePriority + 1;
				
				//loop
				while (current) {
					//found position
					if (r._typePriority > current._typePriority)
						break;
					
					//increment
					last = current;
					current = current._typeNext as RollbackableEntity;
				}
				
				//insert
				if(!current) {
					//end of list
					
					//connect
					last._typeNext = r;
					r._typePrev = last;
					r._typeNext = null;
				}else {
					//insert here
					
					//connect
					r._typeNext = current;
					if (current == _typeFirst[e._type]) {
						//is the head
						_typeFirst[e._type] = r;
						r._typePrev = null;
					}else {
						//not the head
						r._typePrev = current._typePrev;
						(r._typePrev)._typeNext = r;
					}
					current._typePrev = r;
				}
				
				//increment
				_typeCount[e._type]++;
			}
		}
		
		/**
		 * Modified to ensure type order 
		 * @param	e
		 */
		override internal function removeType(e:Entity):void {
			//reset priority
			var r:RollbackableEntity = e as RollbackableEntity;
			r._typePriority = 0;
			
			//super
			super.removeType(e);
		}
		
		/**
		 * Initializes the sync point
		 * Called after the preloaded Entities have been added
		 */
		public function beginSync():void {
			_syncPoint = _lastEntity;
		}
		
		/**
		 * Ensures master lists are the same
		 * Adds unrecycled entities from w to this world
		 * @param	w
		 */
		public function synchronize(w:RollbackableWorld):void {
			//default sync point
			if (!w._syncPoint)
				return;
			
			//increment to next
			w._syncPoint = w._syncPoint._next;
			
			//loop
			while (w._syncPoint) {
				//add unrecycled
				var e:Entity = new w._syncPoint._class;
				e._world = this; //force it to be added as recycled
				add(e);
				
				//increment
				w._syncPoint = w._syncPoint._next;
			}
			
			//update
			updateLists();
			
			//set sync points
			_syncPoint = _lastEntity;
			w._syncPoint = w._lastEntity;
		}
		
		/**
		 * Rolls back primitive values of current World's Entities to the old World's Entities
		 * Assumes both worlds have already been synchronized
		 * @param	w	World to be rolled back to
		 */
		public function rollback(orig:Rollbackable):void {
			//declare vars
			var w:RollbackableWorld = orig as RollbackableWorld;
			var thisCurrentEntity:RollbackableEntity = _firstEntity;
			var oldCurrentEntity:RollbackableEntity = w._firstEntity;
			
			//loop through all entities to be rolled back to
			while (oldCurrentEntity) {
				//rollback
				if (oldCurrentEntity._world && !thisCurrentEntity._world) {
					//unrecycle entity and rollback
					unrecycle(thisCurrentEntity);
					thisCurrentEntity.rollback(oldCurrentEntity);
				}else if (!oldCurrentEntity._world && thisCurrentEntity._world) {
					//recycle entity
					recycle(thisCurrentEntity);
				}else if(oldCurrentEntity._world && thisCurrentEntity._world) {
					//just rollback
					thisCurrentEntity.rollback(oldCurrentEntity);
				}
				
				//increment
				thisCurrentEntity = thisCurrentEntity._next;
				oldCurrentEntity = oldCurrentEntity._next;
			}
			
			//update lists
			updateLists();
			w.updateLists();
		}
		
		/**
		 * Untested to see if it removes properly
		 * Modified to remove all
		 * Modified to destroy master list
		 * Modified to destroy private recycled list
		 */
		override public function end():void {
			//super
			super.end();
			
			//remove
			removeAll();
			updateLists();
			destroyRecycled();
			destroyMasterList();
		}
		
		/**
		 * Meant to be called on ending the world. Destroys the entire Master list.
		 * Does not use updateLists because there's no need to -> done at the end of World
		 */
		public function destroyMasterList():void {
			//declare variables
			var e:RollbackableEntity = _firstEntity as RollbackableEntity;
			var n:RollbackableEntity = null;
			
			//loop destroy
			while (e) {
				n = e._next as RollbackableEntity;
				e._next = null;
				e._world = null;
				e.removed();
				e = n;
			}
		}
		
		/**
		 * Clears stored recycled Entities of the Class type.
		 * Done for the custom _recycled of RollbackableWorld
		 * @param	classType		The Class type to clear.
		 */
		private function clearRecycled(classType:Class):void {
			var e:RollbackableEntity = _recycled[classType],
				n:RollbackableEntity;
			while (e)
			{
				n = e._recycleNext as RollbackableEntity;
				e._recyclePrev = null;
				e._recycleNext = null;
				e = n;
			}
			delete _recycled[classType];
		}
		
		/**
		 * Clears stored recycled Entities of all Class types.
		 * Done for the custom _recycled of RollbackableWorld
		 */
		public function destroyRecycled():void {
			for (var classType:Object in _recycled) clearRecycled(classType as Class);
		}
		
		/**
		 * temp debug
		 * @return
		 */
		public function toString():String {
			var result:String = "Class\tactive\tx, y\n";
			var entity:RollbackableEntity = _firstEntity;
			while (entity != null) {
				result += entity.toString();
				if (entity == _syncPoint)
					result += "\tsync";
				result += "\n";
				
				entity = entity._next;
			}
			return result;
		}
		
		// Rollback information.
		 /** @private */ private var _firstEntity:RollbackableEntity;
		 /** @private */ private var _lastEntity:RollbackableEntity;
		 /** @private */ private var _syncPoint:RollbackableEntity;
		 
		// Fake recycle; since rollbackable words cannot use static entities
		/** @private */	private var _recycled:Dictionary = new Dictionary;
	}
}