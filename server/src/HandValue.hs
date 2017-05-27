module HandValue where

import Types
import CardUtilities
import Data.List
import Data.Function

numCardsInHand :: Int
numCardsInHand = 5

straightFlush :: [Card] -> Bool
straightFlush = undefined

flush :: [Card] -> Bool
flush cards' = maximum (numOfSuit cards') >= numCardsInHand

-- if there's an ace, check for a straight with ace being high and low
-- note - if 7 cards aren't passed to this, it won't work correctly
straight :: [Card] -> Bool
straight c = isStraight x || isStraight x' || isStraight x''
    where x = take 5 fixed
          x' = take 5 $ drop 1 fixed
          x'' = drop 2 fixed
          fixed = sorted c

{- difference between max and min = 4 means it's a straight
example: 2,3,4,5,6 -> 6 - 2 == 4 
5 cards should be passed to this function. -}
isStraight :: [Card] -> Bool
isStraight c = f values || f valuesAceLow
    where f v = maximum v - minimum v == straightDifference
          valuesAceLow = cardValues c False
          values = cardValues c True
          straightDifference = 4

cardValues :: [Card] -> Bool -> [Int]
cardValues c aceHigh
    | aceHigh = map (cardValue . getValue) c
    | otherwise = map (cardValueAceLow . getValue) c

numOfSuit :: [Card] -> [Int]
numOfSuit c = map (`numSuit` c) [isHeart, isClub, isDiamond, isSpade]

numSuit :: (a -> Bool) -> [a] -> Int
numSuit f x = length $ filter f x

isHeart :: Card -> Bool
isHeart x = x `elem` hearts

isClub :: Card -> Bool
isClub x = x `elem` clubs

isDiamond :: Card -> Bool
isDiamond x = x `elem` diamonds

isSpade :: Card -> Bool
isSpade x = x `elem` spades

sorted :: [Card] -> [Card]
sorted = sortBy (compare `on` getValue)

getValue :: Card -> Value
getValue (Card v _) = v

hasAce :: Card -> Bool
hasAce (Card Ace _) = True
hasAce _ = False

cardValue :: Value -> Int
cardValue Two = 2
cardValue c = 1 + cardValue (pred c)

cardValueAceLow :: Value -> Int
cardValueAceLow Ace = 1
cardValueAceLow Two = 2
cardValueAceLow c = 1 + cardValueAceLow (pred c)
