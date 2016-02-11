{-# LANGUAGE OverloadedStrings #-}

module Empire.Server.Graph where

import           Control.Monad.State               (StateT)
import qualified Data.Binary                       as Bin
import           Data.ByteString                   (ByteString)
import           Data.ByteString.Lazy              (fromStrict)
import qualified Data.IntMap                       as IntMap
import qualified Data.Map                          as Map
import           Data.Maybe                        (fromMaybe)
import qualified Data.Text.Lazy                    as Text
import           Prologue

import           Empire.API.Data.DefaultValue      (Value (..))
import           Empire.API.Data.GraphLocation     (GraphLocation)
import           Empire.API.Data.Node              (Node (..), NodeId)
import qualified Empire.API.Data.Node              as Node
import           Empire.API.Data.Port              (InPort (..), OutPort (..), Port (..), PortId (..), PortState (..))
import           Empire.API.Data.ValueType         (ValueType (..))
import qualified Empire.API.Graph.AddNode          as AddNode
import qualified Empire.API.Graph.CodeUpdate       as CodeUpdate
import qualified Empire.API.Graph.Connect          as Connect
import qualified Empire.API.Graph.Disconnect       as Disconnect
import qualified Empire.API.Graph.GetProgram       as GetProgram
import qualified Empire.API.Graph.NodeResultUpdate as NodeResultUpdate
import qualified Empire.API.Graph.NodeUpdate       as NodeUpdate
import qualified Empire.API.Graph.RemoveNode       as RemoveNode
import qualified Empire.API.Graph.RenameNode       as RenameNode
import qualified Empire.API.Graph.SetDefaultValue  as SetDefaultValue
import qualified Empire.API.Graph.UpdateNodeMeta   as UpdateNodeMeta
import qualified Empire.API.Topic                  as Topic
import qualified Empire.API.Update                 as Update
import qualified Empire.Commands.Graph             as Graph
import qualified Empire.Empire                     as Empire
import           Empire.Env                        (Env)
import qualified Empire.Env                        as Env
import           Empire.Server.Server              (errorMessage, sendToBus, withGraphLocation)
import           Flowbox.Bus.BusT                  (BusT (..))
import qualified Flowbox.System.Log.Logger         as Logger

logger :: Logger.LoggerIO
logger = Logger.getLoggerIO $(Logger.moduleName)

notifyCodeUpdate :: GraphLocation -> StateT Env BusT ()
notifyCodeUpdate location = do
    currentEmpireEnv <- use Env.empireEnv
    (resultCode, _) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.getCode location
    case resultCode of
        Left err -> logger Logger.error $ errorMessage <> err
        Right code -> do
            let update = CodeUpdate.Update location $ Text.pack code
            sendToBus Topic.codeUpdate update

notifyNodeUpdate :: GraphLocation -> Node -> StateT Env BusT ()
notifyNodeUpdate location node = do
    let update = NodeUpdate.Update location node
    sendToBus Topic.nodeUpdate update

notifyNodeResultUpdates :: GraphLocation -> StateT Env BusT ()
notifyNodeResultUpdates location = do
    currentEmpireEnv <- use Env.empireEnv
    (result, newEmpireEnv) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.runGraph location
    case result of
        Left err -> logger Logger.error $ errorMessage <> err
        Right valuesMap -> do
            Env.empireEnv .= newEmpireEnv
            mapM_ (uncurry $ notifyNodeResultUpdate location) $ IntMap.assocs valuesMap

notifyNodeResultUpdate :: GraphLocation -> NodeId -> Value -> StateT Env BusT ()
notifyNodeResultUpdate location nodeId value = do
    let update = NodeResultUpdate.Update location nodeId value
    sendToBus Topic.nodeResultUpdate update


data Expr = Expression String | Function (Maybe String) | Module (Maybe String) | Input (Maybe String)| Output (Maybe String)

parseExpr :: String -> Expr
parseExpr ('d':'e':'f':' ':name) = Function $ Just name
parseExpr "def"          = Function Nothing
parseExpr ('m':'o':'d':'u':'l':'e':' ':name) = Module $ Just name
parseExpr "module" = Module Nothing
parseExpr ('i':'n':' ':name) = Input $ Just name
parseExpr "in" = Input Nothing
parseExpr ('o':'u':'t':' ':name) = Output $ Just name
parseExpr "out" = Output Nothing
parseExpr expr = Expression expr

handleAddNode :: ByteString -> StateT Env BusT ()
handleAddNode content = do
    let request  = Bin.decode . fromStrict $ content :: AddNode.Request
        location = request ^. AddNode.location
    currentEmpireEnv <- use Env.empireEnv
    (result, newEmpireEnv) <- case request ^. AddNode.nodeType of
      AddNode.ExpressionNode expression -> case parseExpr expression of
        Expression expression -> liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.addNode
                                                                                                location
                                                                                                (Text.pack $ expression)
                                                                                                (request ^. AddNode.nodeMeta)
        Function name -> return (Right node, currentEmpireEnv) where
          node = Node 42 (Text.pack $ fromMaybe "function0" name) (Node.FunctionNode ["Int", "String"]) mempty (request ^. AddNode.nodeMeta)
        Module   name -> return (Right node, currentEmpireEnv) where
          node = Node 43 (Text.pack $ fromMaybe "module0" name) (Node.ModuleNode) mempty (request ^. AddNode.nodeMeta)
        Input    name -> return (Right node, currentEmpireEnv) where
          node = Node 44 (Text.pack $ fromMaybe "input0" name) (Node.InputNode 1) ports (request ^. AddNode.nodeMeta) where
            ports = Map.fromList [ (OutPortId All,  Port (OutPortId All)  (ValueType "Int") NotConnected)]
        Output   name -> return (Right node, currentEmpireEnv) where
          node = Node 45 (Text.pack $ fromMaybe "output0" name) (Node.OutputNode 1) ports (request ^. AddNode.nodeMeta) where
            ports = Map.fromList [ (InPortId (Arg 0),  Port (InPortId (Arg 0))  (ValueType "Int") NotConnected)]
      AddNode.InputNode _ _ -> return (Left "Input Nodes not yet supported", currentEmpireEnv)
    case result of
        Left err -> logger Logger.error $ errorMessage <> err
        Right node -> do
            Env.empireEnv .= newEmpireEnv
            let update = Update.Update request $ AddNode.Result node
            sendToBus Topic.addNodeUpdate update
            notifyCodeUpdate location
            notifyNodeResultUpdates location

handleRemoveNode :: ByteString -> StateT Env BusT ()
handleRemoveNode content = do
    let request = Bin.decode . fromStrict $ content :: RemoveNode.Request
        location = request ^. RemoveNode.location
    currentEmpireEnv <- use Env.empireEnv
    (result, newEmpireEnv) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.removeNode
        location
        (request ^. RemoveNode.nodeId)
    case result of
        Left err -> logger Logger.error $ errorMessage <> err
        Right _ -> do
            Env.empireEnv .= newEmpireEnv
            let update = Update.Update request $ Update.Ok
            sendToBus Topic.removeNodeUpdate update
            notifyCodeUpdate location
            notifyNodeResultUpdates location

handleUpdateNodeMeta :: ByteString -> StateT Env BusT ()
handleUpdateNodeMeta content = do
    let request = Bin.decode . fromStrict $ content :: UpdateNodeMeta.Request
        nodeMeta = request ^. UpdateNodeMeta.nodeMeta
    currentEmpireEnv <- use Env.empireEnv
    (result, newEmpireEnv) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.updateNodeMeta
        (request ^. UpdateNodeMeta.location)
        (request ^. UpdateNodeMeta.nodeId)
        nodeMeta
    case result of
        Left err -> logger Logger.error $ errorMessage <> err
        Right _ -> do
            Env.empireEnv .= newEmpireEnv
            let update = Update.Update request $ UpdateNodeMeta.Result nodeMeta
            sendToBus Topic.updateNodeMetaUpdate update

handleRenameNode :: ByteString -> StateT Env BusT ()
handleRenameNode content = do
    let request  = Bin.decode . fromStrict $ content :: RenameNode.Request
        location = request ^. RenameNode.location
    currentEmpireEnv <- use Env.empireEnv
    (result, newEmpireEnv) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.renameNode
        (request ^. RenameNode.location)
        (request ^. RenameNode.nodeId)
        (request ^. RenameNode.name)
    case result of
        Left err -> logger Logger.error $ errorMessage <> err
        Right _ -> do
            Env.empireEnv .= newEmpireEnv
            let update = Update.Update request $ Update.Ok
            sendToBus Topic.renameNodeUpdate update
            notifyCodeUpdate location

handleConnect :: ByteString -> StateT Env BusT ()
handleConnect content = do
    let request = Bin.decode . fromStrict $ content :: Connect.Request
        location = request ^. Connect.location
    currentEmpireEnv <- use Env.empireEnv
    (result, newEmpireEnv) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.connect
        location
        (request ^. Connect.src)
        (request ^. Connect.dst)
    case result of
        Left err -> logger Logger.error $ errorMessage <> err
        Right node -> do
            Env.empireEnv .= newEmpireEnv
            let update = Update.Update request $ Update.Ok
            sendToBus Topic.connectUpdate update
            notifyNodeUpdate location node
            notifyCodeUpdate location
            notifyNodeResultUpdates location

handleDisconnect :: ByteString -> StateT Env BusT ()
handleDisconnect content = do
    let request = Bin.decode . fromStrict $ content :: Disconnect.Request
        location = request ^. Disconnect.location
    currentEmpireEnv <- use Env.empireEnv
    (result, newEmpireEnv) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.disconnect
        location
        (request ^. Disconnect.dst)
    case result of
        Left err -> logger Logger.error $ errorMessage <> err
        Right node -> do
            Env.empireEnv .= newEmpireEnv
            let update = Update.Update request $ Update.Ok
            sendToBus Topic.disconnectUpdate update
            notifyNodeUpdate location node
            notifyCodeUpdate location
            notifyNodeResultUpdates location

handleSetDefaultValue :: ByteString -> StateT Env BusT ()
handleSetDefaultValue content = do
    let request = Bin.decode . fromStrict $ content :: SetDefaultValue.Request
        location = request ^. SetDefaultValue.location
    currentEmpireEnv <- use Env.empireEnv
    (result, newEmpireEnv) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.setDefaultValue
        location
        (request ^. SetDefaultValue.portRef)
        (request ^. SetDefaultValue.defaultValue)
    case result of
        Left err -> logger Logger.error $ errorMessage <> err
        Right node -> do
            Env.empireEnv .= newEmpireEnv
            let update = Update.Update request $ Update.Ok
            sendToBus Topic.setDefaultValueUpdate update
            notifyNodeUpdate location node
            notifyCodeUpdate location
            notifyNodeResultUpdates location

handleGetProgram :: ByteString -> StateT Env BusT ()
handleGetProgram content = do
    let request = Bin.decode . fromStrict $ content :: GetProgram.Request
        location = request ^. GetProgram.location
    currentEmpireEnv <- use Env.empireEnv
    (resultGraph, _) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.getGraph location
    (resultCode,  _) <- liftIO $ Empire.runEmpire currentEmpireEnv $ withGraphLocation Graph.getCode  location
    case (resultGraph, resultCode) of
        (Left err, _) -> logger Logger.error $ errorMessage <> err
        (_, Left err) -> logger Logger.error $ errorMessage <> err
        (Right graph, Right code) -> do
            let update = Update.Update request $ GetProgram.Status graph (Text.pack code)
            sendToBus Topic.programStatus update
            notifyNodeResultUpdates location