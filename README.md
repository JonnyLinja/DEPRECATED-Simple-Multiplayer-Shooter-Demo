SIMPLE MULTIPLAYER SHOOTER
==========================

Sample code showing use of MultiPunk.


SETUP
=====

#### > DOWNLOAD

* https://github.com/SelfPossessed/Simple-Multiplayer-Shooter/downloads is a zip containing the project files and images

#### > SERVER

* Follow PlayerIO instructions to make a game (http://playerio.com/documentation/gettingstarted/flashcombopackage)
* Use the Game.cs (bounce server code) provided in the Simple Multiplayer Shooter

#### > CLIENT

* Set the GAME_ID variable in PlayerIOQuickStartWorld to the ID of the game you made at PlayerIO

SERVER
======

The server is a simple bounce server. It takes the first two people who join and matches them into a game.

CODE
====

* Look at the code in the "worlds", "entities", and "general" folders. That's all you have to do to make this game. The rest is the engine.
* https://github.com/SelfPossessed/FlashPunk has more documentation