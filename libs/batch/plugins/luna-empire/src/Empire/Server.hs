{-# LANGUAGE BangPatterns     #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TemplateHaskell  #-}

module Empire.Server where

import           Flowbox.Prelude
import           Control.Monad                          (forever)
import           Control.Monad.State                    (StateT, evalStateT)
import           Data.ByteString                        (ByteString)
import           Data.ByteString.Char8                  (unpack)
import qualified Data.Map.Strict                        as Map
import           Empire.Env                             (Env)
import qualified Flowbox.Bus.Bus                        as Bus
import           Flowbox.Bus.BusT                       (BusT (..))
import qualified Flowbox.Bus.BusT                       as Bus
import qualified Flowbox.Bus.Data.Message               as Message
import           Flowbox.Bus.Data.MessageFrame          (MessageFrame (MessageFrame))
import           Flowbox.Bus.Data.Topic                 (Topic)
import           Flowbox.Bus.EndPoint                   (BusEndPoints)
import qualified Flowbox.System.Log.Logger              as Logger
import qualified Empire.Utils                           as Utils
import qualified Empire.Handlers                        as Handlers


logger :: Logger.LoggerIO
logger = Logger.getLoggerIO $(Logger.moduleName)

run :: BusEndPoints -> [Topic] -> IO (Either Bus.Error ())
run endPoints topics = Bus.runBus endPoints $ do
    logger Logger.info $ "Subscribing to topics: " ++ show topics
    logger Logger.info $ show endPoints
    mapM_ Bus.subscribe topics
    Bus.runBusT $ evalStateT (forever handleMessage) def

handleMessage :: StateT Env BusT ()
handleMessage = do
    msgFrame <- lift $ BusT Bus.receive'
    case msgFrame of
        Left err -> logger Logger.error $ "Unparseable message: " ++ err
        Right (MessageFrame msg crlID senderID lastFrame) -> do
            let topic = msg ^. Message.topic
                logMsg =  show senderID
                       ++ " -> "
                       ++ " (last = "
                       ++ show lastFrame
                       ++ ")"
                       ++ "\t:: "
                       ++ topic
                content = msg ^. Message.message
                errorMsg = show content
            case Utils.lastPart '.' topic of
                "update"   -> handleUpdate  logMsg topic content
                "request"  -> handleRequest logMsg topic content
                _          -> do logger Logger.error logMsg
                                 logger Logger.error errorMsg

handleRequest :: String -> String -> ByteString -> StateT Env BusT ()
handleRequest logMsg topic content = do
    logger Logger.info logMsg
    let handler = Map.findWithDefault defaultHandler topic Handlers.handlersMap
    handler content

defaultHandler :: ByteString -> StateT Env BusT ()
defaultHandler content = do
    logger Logger.info $ "Not recognized request"
    logger Logger.info $ unpack content

handleUpdate :: String -> String -> ByteString -> StateT Env BusT ()
handleUpdate logMsg topic content = do
    logger Logger.info logMsg
    -- logger Logger.info $ unpack content
