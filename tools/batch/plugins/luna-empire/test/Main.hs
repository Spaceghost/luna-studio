{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Prologue
import qualified Data.Binary                      as Bin
import qualified Data.ByteString                  as ByteString
import qualified Data.ByteString.Char8            as Char8 (pack)
import           Data.ByteString.Lazy             (fromStrict, toStrict)
import qualified Flowbox.Config.Config            as Config
import qualified Flowbox.Bus.EndPoint             as EP
import qualified Flowbox.Bus.Bus                  as Bus
import qualified Flowbox.Bus.Data.Flag            as Flag
import qualified Flowbox.Bus.Data.Message         as Message
import           Flowbox.Options.Applicative      (short, long, help, metavar)
import qualified Flowbox.Options.Applicative      as Opt
import qualified Empire.API.Data.Node             as Node
import qualified Empire.API.Data.NodeMeta         as NodeMeta
import qualified Empire.API.Data.NodeMeta         as NodeMeta
import qualified Empire.API.Data.GraphLocation    as GraphLocation
import qualified Empire.API.Data.Breadcrumb       as Breadcrumb
import qualified Empire.API.Graph.AddNode         as AddNode
import qualified Empire.API.Graph.RemoveNode      as RemoveNode
import qualified Empire.API.Project.CreateProject as CreateProject
import qualified Empire.API.Project.ListProjects  as ListProjects
import qualified Empire.API.Library.CreateLibrary as CreateLibrary
import qualified Empire.API.Library.ListLibraries as ListLibraries
import qualified Empire.API.Topic                 as Topic
import qualified Empire.API.Update                as Update


data Cmd = TestNotRecognizedRequest
         | TestBadTopic
         | TestAddNode
         | TestRemoveNode
         | TestNodeUpdate
         deriving Show

parser :: Opt.Parser Cmd
parser = Opt.flag' TestNotRecognizedRequest (long "nrr" <> help "Not Recognized Request")
     <|> Opt.flag' TestBadTopic             (long "bt"  <> help "Bad Topic")
     <|> Opt.flag' TestAddNode              (long "an"  <> help "Add Node")
     <|> Opt.flag' TestRemoveNode           (long "rn"  <> help "Remove Node")
     <|> Opt.flag' TestNodeUpdate           (long "nu"  <> help "Node Update")

run :: Cmd -> IO ()
run cmd = case cmd of
    TestNotRecognizedRequest -> testNotRecognizedRequest
    TestBadTopic             -> testBadTopic
    TestAddNode              -> testAddNode
    TestRemoveNode           -> testRemoveNode
    TestNodeUpdate           -> testNodeUpdate


opts :: Opt.ParserInfo Cmd
opts = Opt.info (Opt.helper <*> parser)
                (Opt.fullDesc <> Opt.header "ver 0.1")

main = Opt.execParser opts >>= run

-- tests

gl :: Int -> Int -> GraphLocation.GraphLocation
gl pid lid = GraphLocation.GraphLocation pid lid (Breadcrumb.Breadcrumb [])

testNotRecognizedRequest :: IO ()
testNotRecognizedRequest = do
    endPoints <- EP.clientFromConfig <$> Config.load
    void $ Bus.runBus endPoints $ do
        Bus.send Flag.Enable $ Message.Message "empire.hello.request" (Char8.pack "basic string")

testBadTopic :: IO ()
testBadTopic = do
    endPoints <- EP.clientFromConfig <$> Config.load
    void $ Bus.runBus endPoints $ do
        Bus.send Flag.Enable $ Message.Message "any-hello" ByteString.empty

testAddNode :: IO ()
testAddNode = do
    endPoints <- EP.clientFromConfig <$> Config.load
    let content = toStrict . Bin.encode $ AddNode.Request (gl 0 0) (AddNode.ExpressionNode "expres") (NodeMeta.NodeMeta (1.2, 3.4)) 7
    void $ Bus.runBus endPoints $ do
        Bus.send Flag.Enable $ Message.Message Topic.addNodeRequest content

testRemoveNode :: IO ()
testRemoveNode = do
    endPoints <- EP.clientFromConfig <$> Config.load
    let content = toStrict . Bin.encode $ RemoveNode.Request (gl 0 0) 3
    void $ Bus.runBus endPoints $ do
        Bus.send Flag.Enable $ Message.Message Topic.removeNodeRequest content

testNodeUpdate :: IO ()
testNodeUpdate = do
    endPoints <- EP.clientFromConfig <$> Config.load
    void $ Bus.runBus endPoints $ do
        let meta    = NodeMeta.NodeMeta (20.0, 30.0)
            request = AddNode.Request (gl 0 0) (AddNode.ExpressionNode "dupa123") meta 1235
            node    = Node.Node 123 "node0" (Node.ExpressionNode "dupa123") mempty meta
            result  = AddNode.Result node
            update  = Update.Update request result
        Bus.send Flag.Enable $ Message.Message Topic.addNodeUpdate $ toStrict $ Bin.encode update