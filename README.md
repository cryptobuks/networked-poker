# networked-poker
A collection of programs to allow multiple clients to play poker together on one server, with a GUI for clients, and an AI to play against.

Local server gameplay is pretty good, just started adding network support and initial network work on the client.

## Installation

#### Install prerequistes
You need stack installed.

##### Debian based:
`sudo apt-get install haskell-stack`

##### Arch based:
`sudo pacman -S stack`

#### Clone the repository

`git clone https://github.com/ZedPea/networked-poker.git`

`cd networked-poker`

#### Compile and install

`stack install`

If you want to try the functional local game, run instead

`stack install --flag server:debug`

It is currently non functional.

Then either add ~/.local/bin to your path and run the executable of your choice:

`ai`
`client`
`server`

Or, run

`stack exec ai`
`stack exec client`
`stack exec server`

## Tests

#### Install prerequisites
You need poker-eval/libpoker-eval installed. 

It seems the source URL is down at the moment, I found it on github and compiled it, with
`./configure`, `make`, `make install`, however for stack to find it I had to copy the library from `/usr/local/lib/` to `/lib/`

#### Running

`stack test`
