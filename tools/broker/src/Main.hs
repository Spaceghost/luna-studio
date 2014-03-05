
---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
module Main where

import qualified Control.Concurrent as Concurrent

import           Flowbox.Broker.Cmd                           (Cmd)
import qualified Flowbox.Broker.Cmd                           as Cmd
import qualified Flowbox.Broker.Control.Handler.BrokerHandler as BrokerHandler
import qualified Flowbox.Broker.Control.Server                as Control
import qualified Flowbox.Broker.Proxy                         as Proxy
import qualified Flowbox.Broker.Version                       as Version
import           Flowbox.Options.Applicative                  hiding (info)
import qualified Flowbox.Options.Applicative                  as Opt
import           Flowbox.Prelude                              hiding (error)
import           Flowbox.System.Log.Logger


rootLogger :: Logger
rootLogger = getLogger "Flowbox"


logger :: LoggerIO
logger = getLoggerIO "Flowbox.Broker"


defaultCtrlEndPoint :: String
defaultCtrlEndPoint = "tcp://*:30530"

defaultPullEndPoint :: String
defaultPullEndPoint = "tcp://*:30531"

defaultPubEndPoint :: String
defaultPubEndPoint  = "tcp://*:30532"


parser :: Parser Cmd
parser = Opt.flag' Cmd.Version (long "version" <> hidden)
       <|> Cmd.Serve
           <$> strOption ( long "ctrl-addr" <> short 'c' <> value defaultCtrlEndPoint <> metavar "endpoint" <> help "Server control endpoint" )
           <*> strOption ( long "pull-addr" <> short 'l' <> value defaultPullEndPoint <> metavar "endpoint" <> help "Server pull endpoint"    )
           <*> strOption ( long "pub-addr"  <> short 'b' <> value defaultPubEndPoint  <> metavar "endpoint" <> help "Server publish endpoint" )
           <*> optIntFlag (Just "verbose") 'v' 2 3          "Verbose level (level range is 0-5, default level is 3)"
           <*> switch    ( long "no-color"          <> help "Disable color output" )


opts :: ParserInfo Cmd
opts = Opt.info (helper <*> parser)
                (Opt.fullDesc <> Opt.header (Version.full False))


main :: IO ()
main = execParser opts >>= run


run :: Cmd -> IO ()
run cmd = case cmd of
    Cmd.Version  -> putStrLn (Version.full False) -- TODO [PM] hardcoded numeric = False
    Cmd.Serve {} -> do
        rootLogger setIntLevel $ Cmd.verbose cmd
        logger info "Starting proxy service"
        _ <- Concurrent.forkIO $ Proxy.run (Cmd.pullEndPoint cmd) (Cmd.pubEndPoint cmd)
        logger info "Starting control service"
        h <- BrokerHandler.empty
        Control.run (Cmd.ctrlEndPoint cmd) h
