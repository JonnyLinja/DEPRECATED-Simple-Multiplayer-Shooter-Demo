using System;
using System.Collections.Generic;
using System.Text;
using System.Collections;
using PlayerIO.GameLibrary;
using System.Drawing;

namespace MyGame {
	public class Player : BasePlayer {
		public string Name;
        //public int ping; //should calculate it weighted instead
	}

    [RoomType("Shooter")]
	public class GameCode : Game<Player> {
        //constants
        private const String lobby = "LOBBY";
        private const String poke = "P";
        private const String room = "R";
        private const String start = "S";
        private const String command = "C";

        //players
        private Player p1, p2;

        //thread synchronization
        private Object lockThis = new Object();

        private Boolean isLobby() {
            return (RoomId == GameCode.lobby);
        }

		public override void GameStarted() {
		}

		public override void GameClosed() {
		}

		public override void UserJoined(Player player) {
            lock (lockThis) {
                if (p1 == null)
                    p1 = player;
                else if (p2 == null) {
                    p2 = player;
                    if (isLobby()) {
                        String newRoom = (DateTime.Now.Ticks - new DateTime(2011, 1, 1).Ticks).ToString();
                        p1.Send(GameCode.room, newRoom);
                        p2.Send(GameCode.room, newRoom);
                        p1 = null;
                        p2 = null;
                    }else {
                        p1.Send(GameCode.start, true);
                        p2.Send(GameCode.start, false);
                    }
                }
            }
		}
        
		public override void UserLeft(Player player) {
            if (!isLobby())
                return;

            lock (lockThis) {
                if (p1 != null && p1 == player) {
                    p1 = p2;
                    p2 = null;
                }else if(p2 != null && p2 == player) {
                    p2 = null;
                }
            }
		}

		public override void GotMessage(Player player, Message message) {
            //join
            if (isLobby()) {
                player.Send(GameCode.poke);
                return;
            }

            //play
			switch(message.Type) {
                case GameCode.command: //command
					if (player == p1)
						p2.Send(message);
					else if (player == p2)
						p1.Send(message);
					break;
			}
		}














		Point debugPoint;

		// This method get's called whenever you trigger it by calling the RefreshDebugView() method.
		public override System.Drawing.Image GenerateDebugImage() {
			// we'll just draw 400 by 400 pixels image with the current time, but you can
			// use this to visualize just about anything.
			var image = new Bitmap(400,400);
			using(var g = Graphics.FromImage(image)) {
				// fill the background
				g.FillRectangle(Brushes.Blue, 0, 0, image.Width, image.Height);

				// draw the current time
				g.DrawString(DateTime.Now.ToString(), new Font("Verdana",20F),Brushes.Orange, 10,10);

				// draw a dot based on the DebugPoint variable
				g.FillRectangle(Brushes.Red, debugPoint.X,debugPoint.Y,5,5);
			}
			return image;
		}

		// During development, it's very usefull to be able to cause certain events
		// to occur in your serverside code. If you create a public method with no
		// arguments and add a [DebugAction] attribute like we've down below, a button
		// will be added to the development server. 
		// Whenever you click the button, your code will run.
		[DebugAction("Play", DebugAction.Icon.Play)]
		public void PlayNow() {
			Console.WriteLine("The play button was clicked!");
		}

		// If you use the [DebugAction] attribute on a method with
		// two int arguments, the action will be triggered via the
		// debug view when you click the debug view on a running game.
		[DebugAction("Set Debug Point", DebugAction.Icon.Green)]
		public void SetDebugPoint(int x, int y) {
			debugPoint = new Point(x,y);
		}
	}
}