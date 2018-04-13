module Main
(
    main
)
where

import AIFramework (runAI)
import AIRandom (handleFunc)

main :: IO ()
main = runAI "ai-random" handleFunc
