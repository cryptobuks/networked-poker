module LaunchServer
(
    launchServer,
    launchServerWithShuffle
)
where

import Data.ByteString.Lazy (ByteString, fromStrict)
import Network.Socket.ByteString (recv)
import Control.Concurrent.MVar (MVar, newMVar, modifyMVar_)
import Control.Concurrent (forkIO)
import Control.Monad (void, forever, when)
import Text.Printf (printf)
import Data.Binary (decodeOrFail)
import Data.Binary.Get (ByteOffset)
import Control.Monad.Trans.State (evalStateT, get)
import Control.Monad.Trans.Class (lift)
import System.IO.Error (tryIOError)
import System.Environment (getArgs)
import Data.Either (isLeft)
import Data.IORef (IORef, writeIORef)
import Control.Lens ((^.), (^..), traversed)
import Data.Text (Text, unpack)

import System.Log.Logger 
    (Priority(..), updateGlobalLogger, rootLoggerName, setLevel, infoM,
     debugM)

import Network.Socket 
    (Socket, SockAddr, SocketOption(..), getAddrInfo, socket, addrFamily,
     addrSocketType, bind, addrAddress, listen, accept, isReadable,
     addrProtocol, isSupportedSocketOption, setSocketOption, close)

import Graphics.QML 
    (ObjRef, initialDocument, contextObject, newClass, defMethod', newObject,
     defaultEngineConfig, fileDocument, anyObjRef, runEngineLoop)

import Utilities.Player (mkNewPlayer)
import Utilities.Card (dealCards, fullDeck)
import Utilities.Types (mkCGame, mkGame)
import DrawCard (getInitFunc, getRNGFunc, initM)
import Game (gameLoop)
import Output (outputGameOver, outputInitialGame)
import Lenses (nextRoundShuffleType, playerQueue, players, socket,
               shuffleType, algorithm, randomSource)

import Types
    (GameStateT, Player(..), ShuffleType(..), Deck(..), 
     ShuffleType(..), DrawAlgorithm(..), RandomSource(..), RandomIndexDeck(..))

import Paths_server (getDataFileName)

launchServer :: IO ()
launchServer = launchServerWithShuffle (ShuffleType RandomIndex LEucyer)

launchServerWithShuffle :: ShuffleType -> IO ()
launchServerWithShuffle shuffleType' = do
    args <- getArgs

    let level | "--debug" `elem` args = DEBUG
              | "--info" `elem` args = INFO
              | otherwise = WARNING

    updateGlobalLogger rootLoggerName (setLevel level)

    infoM "Prog.Main" "Starting server"

    addr:_ <- getAddrInfo Nothing (Just "127.0.0.1") (Just "2112")
    sock <- Network.Socket.socket (addrFamily addr) (addrSocketType addr)
                                  (addrProtocol addr)

    -- c api -> 1 = true, 0 = false
    let reuse = if isSupportedSocketOption ReuseAddr
                    then 1
                    else 0

    debugM "Prog.Main" ("ReuseAddr = " ++ show reuse)

    setSocketOption sock ReuseAddr reuse

    maybeBound <- tryIOError $ bind sock (addrAddress addr)

    when (isLeft maybeBound) . error $ 
        "Socket already bound. Ensure you aren't running another " ++
        "copy of the server."

    infoM "Prog.Main" "Listening for connections"

    -- maximum number of queued connections, apparently set at 5 for
    -- most OS's. Need to look into. Queued connections should be
    -- accepted very fast? Loop is very simple.
    listen sock 5

    unseated <- newMVar []

    forever $ listenForConnections sock unseated shuffleType'

listenForConnections :: Socket -> MVar [Player] -> ShuffleType -> IO ()
listenForConnections localSock unseated shuffleType' = do
    (sock, addr) <- accept localSock

    infoM "Prog.listenForConnections" 
          (printf "Connection made on %s..." (show addr))

    void . forkIO $ handleNewClient sock addr unseated shuffleType'

handleNewClient :: Socket -> SockAddr -> MVar [Player] -> ShuffleType -> IO ()
handleNewClient sock addr unseated shuffleType' = do
    readable <- isReadable sock

    if readable
        then do
            -- add a timer here?
            msg <- recv sock 4096

            handleMsg (decodeOrFail $ fromStrict msg) sock addr unseated
                       shuffleType'
        else error "Socket is unreadable..."

handleMsg :: Either (ByteString, ByteOffset, String) 
                    (ByteString, ByteOffset, String) 
          -> Socket -> SockAddr -> MVar [Player] -> ShuffleType -> IO ()
handleMsg (Left (_, _, err)) _ addr _ _ = 
    error $ printf "Couldn't decode recieved message from %s: %s..." 
                   (show addr) err

handleMsg (Right (_, _, msg)) sock addr unseated shuffleType' = do
    infoM "Prog.handleMsg" $
          printf "Recieved message from %s: %s" (show addr) msg

    seatPlayer sock msg unseated shuffleType'

seatPlayer :: Socket -> String -> MVar [Player] -> ShuffleType -> IO ()
seatPlayer sock name' unseated shuffleType' = do
    args <- getArgs

    let numPlayers | "--fullgame" `elem` args = maxPlayers
                   | otherwise = minPlayers

    player <- mkNewPlayer name' sock

    -- this will block if unseated is empty, make sure to set it to [] instead
    modifyMVar_ unseated $ \a -> do
        debugM "Prog.seatPlayer" $
               printf "There are %d players waiting to be seated" 
                      (length a + 1)

        if length a == (numPlayers - 1)
            then do
                launchNewGame (player : a) unseated shuffleType'
                return []
            else return $ player : a

maxPlayers :: Int
maxPlayers = 6

minPlayers :: Int
minPlayers = 2

launchNewGame :: [Player] -> MVar [Player] -> ShuffleType -> IO ()
launchNewGame players' playerChan shuffleType' = do
    infoM "Prog.launchNewGame" "Making new game"

    game' <- mkGame players' playerChan shuffleType'

    void . forkIO $ evalStateT play game'

play :: GameStateT ()
play = do
    setup
    gameLoop
    cleanup

setup :: GameStateT ()
setup = do
    cgame <- mkCGame

    args <- lift getArgs

    s <- get

    let initFunc = getInitFunc (s^.shuffleType.algorithm)
        rngFunc = getRNGFunc (s^.shuffleType.randomSource)

    initM initFunc rngFunc

    lift . when ("--chooseshuffle" `elem` args) $ do

        rootClass <- newClass [
            defMethod' "changeShuffle" $ 
                changeShuffle (s^.nextRoundShuffleType)]

        ctx <- newObject rootClass ()

        gui <- getDataFileName "src/gui/ShufflePicker.qml"

        let config = defaultEngineConfig {
            initialDocument = fileDocument gui,
            contextObject = Just $ anyObjRef ctx
        }

        void . forkIO $ runEngineLoop config

    lift $ infoM "Prog.setup" "Sending initial game to clients..."

    outputInitialGame cgame
    dealCards

cleanup :: GameStateT ()
cleanup = do
    outputGameOver

    s <- get

    lift $ do
        mapM_ close (s^..playerQueue.players.traversed.Lenses.socket)
        infoM "Prog.cleanup" "Game finished"

changeShuffle :: IORef ShuffleType -> ObjRef () -> Text -> Text -> IO ()
changeShuffle shuffleTypeIORef _ algorithm randomSource = do
    let newAlgorithm = read $ unpack algorithm
        newRandomSource = read $ unpack randomSource
        newShuffleType = ShuffleType newAlgorithm newRandomSource

    writeIORef shuffleTypeIORef newShuffleType
