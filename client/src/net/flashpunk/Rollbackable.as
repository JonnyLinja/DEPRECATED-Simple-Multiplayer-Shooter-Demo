package net.flashpunk {
	public interface Rollbackable {
		function rollback(orig:Rollbackable):void;
	}
}