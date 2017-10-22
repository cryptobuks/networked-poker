# networked-poker
[![Build Status](https://travis-ci.org/ZedPea/networked-poker.svg)](https://travis-ci.org/ZedPea/networked-poker)

A collection of programs to allow multiple clients to play poker together on one server, with a GUI for clients, and an AI to play against.

Working on the client GUI, then the networking.

## Installation

#### Install prerequistes
You need stack and QtQuick installed.

##### Debian based:
`sudo apt-get install haskell-stack qtdeclarative5-dev`

##### Arch based:
`sudo pacman -S stack qt5-quickcontrols qt5-quickcontrols`

#### Clone the repository

`git clone https://github.com/ZedPea/networked-poker.git`

`cd networked-poker`

#### Compile and install

`stack install`

Then either add ~/.local/bin to your path and run the executable of your choice:

`ai`
`client`
`server`

Or, run

`stack exec ai`
`stack exec client`
`stack exec server`

#### Flags

`--debug` Enables debug output, for both client and server.

`--info` Does the same, but with a little less output.

`--guionly` On the client launches just the GUI and doesn't do any networking. Helpful for fast prototyping of the GUI.

`--fullgame` On the server launches the game with 6 players instead of 2.

## Thanks

#### Cards
Icons made by Aussiesim - http://game-icons.net/tags/board.html

They fall under the CC 3.0 license - https://creativecommons.org/licenses/by/3.0/

Icons were cropped and resized.

##### Card modifications

Remove black borders:

`mogrify -bordercolor black -border 1x1 -alpha set -channel RGBA -fuzz 80% -fill none -floodfill +0+0 black -shave 1x1 -trim +repage *.png`

Replace black with red where necessary:

`find . \( -iname "*diamonds*" -or -iname "*hearts*" \) -exec mogrify -format png -fill red -opaque black -fuzz 80% {} \;`

Resize:

`mogrify -resize 60x80\! *.png`

#### Card Back and Poker Chip
Icons made by Kenney.nl - https://opengameart.org/content/boardgame-pack

They fall under the CC0 1.0 license - https://creativecommons.org/licenses/by/1.0/

Icons were resized.
