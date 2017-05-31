module TestStates where

import Types
import CardUtilities

testBets :: Bets
testBets = Bets 0 0 10 20

testCards :: Cards
testCards = Cards Nothing fullDeck

testGame :: Game
testGame = Game testPlayers PreFlop testCards False testBets False

testPlayer1 :: Player
testPlayer1 = Player "test" 1000 Nothing True False 0 False

testPlayer2 :: Player
testPlayer2 = Player "test2" 1000 Nothing True False 0 False

testPlayers :: Players
testPlayers = Players 2 [testPlayer1, testPlayer2] 1 0