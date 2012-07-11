using System;
using System.Collections.Generic;
using System.Text;
using System.Collections;
using PlayerIO.GameLibrary;
using System.Drawing;

namespace MyGame {
	public class Player : BasePlayer {
        public const int maxCount = 31; //if send every 33ms, then 1 second to calculate it
        public long[] receivedSyncTimes = new long[maxCount];
        public int receivedSyncCount = 0;
        public int ignoreCount = 100; //if send every 33ms, then 3.3 seconds of ignore to stabilize connection
	}

    [RoomType("Lobby")]
    public class LobbyCode : Game<Player> {
        //const
        private const String MESSAGE_ROOM = "R";
        private const String MESSAGE_POKE = "P";

        //thread synchronization
        private Object lockThis = new Object();

        //players
        private Player p1, p2;

        //match 2 players against each other
        public override void UserJoined(Player player) {
            lock (lockThis) {
                if (p1 == null)
                    //you are first player, save
                    p1 = player;
                else if (p2 == null) {
                    //you are second player, save
                    p2 = player;

                    //lobby, send them to new rooms
                    String newRoom = (DateTime.Now.Ticks - new DateTime(2011, 1, 1).Ticks).ToString();
                    p1.Send(MESSAGE_ROOM, newRoom);
                    p2.Send(MESSAGE_ROOM, newRoom);

                    //reset
                    p1 = null;
                    p2 = null;
                }
            }
        }

        //reset p1/p2 so next two can be hooked up
        public override void UserLeft(Player player) {
            //reset who is 1st player
            lock (lockThis) {
                if (p1 != null && p1 == player) {
                    p1 = p2;
                    p2 = null;
                }else if (p2 != null && p2 == player) {
                    p2 = null;
                }
            }
        }

        //to display ping
        public override void GotMessage(Player player, Message message) {
            player.Send(MESSAGE_POKE);
        }
    }

    [RoomType("Shooter")]
	public class GameCode : Game<Player> {
        //constants
        private const String MESSAGE_START = "S";
        private const String MESSAGE_FIGHT = "F"; //eventually just use start
        private const String MESSAGE_COMMAND = "C";
        private const int START_BUFFER = 5000; //5 seconds - helps both clients start at same time regardless of ping spike

        //room state
        private Boolean fighting = false;
        private long startTime = 0;

        //players
        private Player p1, p2;

        //thread synchronization
        private Object lockThis = new Object();

		public override void UserJoined(Player player) {
            lock (lockThis) {
                if (p1 == null)
                    //you are first player, save
                    p1 = player;
                else if (p2 == null) {
                    //you are second player, save
                    p2 = player;

                    //game, both have entered, send the start indicator
                    p1.Send(GameCode.MESSAGE_START, true);
                    p2.Send(GameCode.MESSAGE_START, false);

                    //save start time
                    startTime = DateTime.Now.Ticks;
                }
            }
		}

		public override void GotMessage(Player player, Message message) {
            //play
			switch(message.Type) {
                //syncing the start time
                case GameCode.MESSAGE_START: {
                    if (!fighting) {
                        if (player.ignoreCount > 0) {
                            //ignore it - wait for it to stabilize
                            player.ignoreCount--;
                        }else {
                            if (player.receivedSyncCount < Player.maxCount) {
                                //store it
                                player.receivedSyncTimes[player.receivedSyncCount++] = DateTime.Now.Ticks;

                                //logging
                                if(p1 == player)
                                    Console.WriteLine("player1 added " + player.receivedSyncTimes[player.receivedSyncCount-1]);
                                else
                                    Console.WriteLine("player2 added " + player.receivedSyncTimes[player.receivedSyncCount-1]);
                            }
                        
                            //calculate start time
                            CalculateStartTime();
                        }
                    }
                    //break
                    break;
                }

                //bounce the commands while playing
                case GameCode.MESSAGE_COMMAND: {
                    if (fighting) {
                        //forward message - bounce server style
                        if (player == p1)
                            p2.Send(message);
                        else if (player == p2)
                            p1.Send(message);
                    }
                    //break
                    break;
                }
			}
		}

        private void CalculateStartTime() {
            //determine both players sent enough commands to begin calculation
            if (p1.receivedSyncCount < (Player.maxCount) || p2.receivedSyncCount < (Player.maxCount))
                return;

            //set game state to fighting
            fighting = true;

            //declare variables
            long[] differences = new long[Player.maxCount];
            long differenceMean = 0;
            Boolean p1Ahead = false;

            //fill differences array
            for (int i = 0; i < Player.maxCount; i++ ) {
                //array of differences
                differences[i] = p1.receivedSyncTimes[i] - p2.receivedSyncTimes[i];
                Console.WriteLine("difference " + i + ": " + differences[i]);

                //sum
                differenceMean += differences[i];
            }

            //calculate mean
            differenceMean /= Player.maxCount;
            Console.WriteLine("difference mean " + differenceMean);

            //set larger
            if (differenceMean > 0)
                p1Ahead = true;

            //standard deviation
            double standardDeviation = 0;
            for (int i = 0; i < Player.maxCount; i++) {
                //sum square of differences
                standardDeviation += Math.Pow(differences[i] - differenceMean, 2);
            }
            //final calculation
            standardDeviation = Math.Sqrt(standardDeviation/Player.maxCount);
            Console.WriteLine("standard deviation is " + standardDeviation);

            //sort differences array
            Array.Sort(differences);

            //final calculation
            differenceMean = 0;
            long median = differences[Player.maxCount/2];
            int count = 0;
            Console.WriteLine("median is " + median);
            for (int i = 0; i < Player.maxCount; i++) {
                Console.WriteLine("testing sort " + i + ": " + differences[i]);
                if (Math.Abs(differences[i] - median) <= standardDeviation) {
                    Console.WriteLine("using " + differences[i]);
                    differenceMean += differences[i];
                    count++;
                }
            }

            //mean of the remaining onces
            differenceMean /= count;
            Console.WriteLine("final mean: " + differenceMean);

            //base delay
            uint delay = (uint)((new TimeSpan(DateTime.Now.Ticks - startTime)).TotalMilliseconds + START_BUFFER);

            if (p1Ahead) {
                p1.Send(GameCode.MESSAGE_FIGHT, true, (uint)(delay + new TimeSpan(differenceMean).TotalMilliseconds));
                p2.Send(GameCode.MESSAGE_FIGHT, false, delay);
            }else {
                p1.Send(GameCode.MESSAGE_FIGHT, true, delay);
                p2.Send(GameCode.MESSAGE_FIGHT, false, (uint)(delay + new TimeSpan(differenceMean).TotalMilliseconds));
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