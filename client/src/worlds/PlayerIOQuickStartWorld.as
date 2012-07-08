package worlds {
	import flash.media.Video;
	import net.flashpunk.World;
	import net.flashpunk.FP;
	
	import general.Utils;
	
	import playerio.*;
	
	import flash.utils.getTimer;
	
	import worlds.ShooterPlayWorld;
	
	/**
	 * Quick hack to get the Flash client playing against another one
	 * Server has 1 lobby room and the rest game rooms
	 * After at least 2 people join a lobby, the server redirects them to play against each other in a new room
	 * After that the server acts like a bounce server
	 */
	public class PlayerIOQuickStartWorld extends World {
		//ping
		private var pokeStart:int;
		
		//local or public server
		private const LOCAL:Boolean = false;
		
		//server general constants
		private const GAME_ID:String = ""; //(Get your own at playerio.com. 1: Create user, 2:Goto admin pannel, 3:Create game, 4: Copy game id inside the "")
		private const SHOOTER_GAME_TYPE:String = "Shooter";
		private const LOBBY_GAME_TYPE:String = "Lobby";
		private const ROOM_LOBBY:String = "LOBBY";
		
		//server message constants
		private const MESSAGE_ROOM_CHANGE:String = "R";
		private const MESSAGE_START:String = "S";
		private const MESSAGE_POKE:String = "P";
		
		//playerio connection
		private var conn:Connection;
		private var client:Client;
		
		public function PlayerIOQuickStartWorld() {
			//super
			super();
		}
		
		override public function begin():void {
			//Connect and join the room
			PlayerIO.connect(
				FP.stage,								//Referance to stage
				GAME_ID,								//Game id
				"public",								//Connection id, default is public
				"GuestUser",							//Username
				"",										//User auth. Can be left blank if authentication is disabled on connection
				"",										//Partner ID
				handleConnect,							//Function executed on successful connect
				handleError								//Function executed if we recive an error
			);
		}
		
		/**
		 * Called on a playerio related error
		 * Displays error message
		 * @param	error
		 */
		private function handleError(error:PlayerIOError):void {
			Utils.log(error.name + ":");
			Utils.log(error.message);
		}
		
		/**
		 * Called on successful connection
		 * Joins the lobby
		 * @param	client
		 */
		private function handleConnect(client:Client):void {
			//local
			if(LOCAL)
				client.multiplayer.developmentServer = "localhost:8184";
			
			//log
			Utils.log("Connected to server")
			
			//join lobby
			client.multiplayer.createJoinRoom(
				ROOM_LOBBY,							//Room id. If set to null a random roomid is used
				LOBBY_GAME_TYPE,					//The game type started on the server
				true,								//Should the room be visible in the lobby?
				{},									//Room data. This data is returned to lobby list. Variabels can be modifed on the server
				{},									//User join data
				handleJoinLobby,					//Function executed on successful joining of the room
				handleError							//Function executed if we got a join error
			);
			
			//store client
			this.client = client;
		}

		/**
		 * Called on joining the lobby
		 * Begins ping checks
		 * Waits for room change message
		 * @param	conn
		 */
		private function handleJoinLobby(conn:Connection):void {
			//log
			Utils.log("joined lobby, waiting for opponent")
			
			//store connection
			this.conn = conn;
			
			//message handlers
			this.conn.addMessageHandler(MESSAGE_ROOM_CHANGE, handleRoomChange);
			this.conn.addMessageHandler(MESSAGE_POKE, handlePoke);
			
			//send ping request
			pokeStart = getTimer();
			this.conn.send(MESSAGE_POKE);
		}
		
		/**
		 * Called on receiving poke
		 * Displays ping
		 * @param	m
		 */
		private function handlePoke(m:Message):void {
			//display ping
			var currentTime:int = getTimer();
			Utils.log("ping: " + (currentTime - pokeStart) + " ms");
			
			//resend ping request
			pokeStart = currentTime;
			if(this.conn.connected)
				this.conn.send(MESSAGE_POKE);
		}
		
		/**
		 * Called on getting a game room
		 * Disconnects from lobby
		 * Joins new room
		 * @param	m
		 */
		private function handleRoomChange(m:Message):void {
			//kill old connection
			this.conn.removeMessageHandler(MESSAGE_POKE, handlePoke);
			this.conn.removeMessageHandler(MESSAGE_ROOM_CHANGE, handleRoomChange);
			this.conn.disconnect();
			this.conn = null;
			
			//log
			var newRoom:String = m.getString(0);
			Utils.log("player found, joining game room " + newRoom);
			
			//join room
			this.client.multiplayer.createJoinRoom(
				newRoom,							//Room id. If set to null a random roomid is used
				SHOOTER_GAME_TYPE,					//The game type started on the server
				true,								//Should the room be visible in the lobby?
				{},									//Room data. This data is returned to lobby list. Variabels can be modifed on the server
				{},									//User join data
				handleJoinGame,						//Function executed on successful joining of the room
				handleError							//Function executed if we got a join error
			);
		}
		
		private function handleJoinGame(conn:Connection):void {
			//log
			Utils.log("joined game room, waiting for other player");
			
			//store connection
			this.conn = conn;
			
			//message handlers
			this.conn.addMessageHandler(MESSAGE_START, handleStart);
		}
		
		/**
		 * Called when is ready -> both players have joined the room
		 * Should not be in title state; move it later
		 * @param	m
		 */
		private function handleStart(m:Message):void {
			//log
			Utils.log("starting game");
			
			//remove handler
			this.conn.removeMessageHandler(MESSAGE_START, handleStart);
			
			//temp debug
			startTime = getTimer();
			isP1 = m.getBoolean(0);
			
			//play game
			FP.world = new ShooterPlayWorld(conn);
		}
		
		//shit
		private var startTime:uint = 0;
		private var isP1:Boolean;
	}

}