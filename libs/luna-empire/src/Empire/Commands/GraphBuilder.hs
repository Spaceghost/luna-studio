module Empire.Commands.GraphBuilder where

import           Prologue
import           Control.Monad.State
import           Control.Monad.Error     (throwError)
import           Data.Map                (Map)
import qualified Data.Map                as Map
import qualified Data.IntMap             as IntMap
import           Data.Maybe              (catMaybes, fromMaybe, maybeToList)
import qualified Data.Text.Lazy          as Text

import           Data.Variants           (match, case', ANY(..))
import           Data.Layer.Coat         (uncoat, coated)

import qualified Empire.Data.Graph       as Graph
import           Empire.Data.Graph       (Graph)

import           Empire.API.Data.Port         (InPort(..), OutPort(..), Port(..), PortId(..))
import           Empire.API.Data.ValueType    (ValueType(..))
import           Empire.API.Data.PortRef      (InPortRef(..), OutPortRef(..))
import           Empire.API.Data.Node         (NodeId)
import           Empire.API.Data.NodeMeta     (NodeMeta(..))
import qualified Empire.API.Data.Node         as API
import qualified Empire.API.Data.Graph        as API
import           Empire.API.Data.DefaultValue (PortDefault(..), Value(..))

import           Empire.Empire
import qualified Empire.Commands.AST        as AST
import           Empire.ASTOp               (ASTOp, runASTOp)
import qualified Empire.ASTOps.Print        as Print
import qualified Empire.ASTOps.Builder      as ASTBuilder
import qualified Empire.Commands.GraphUtils as GraphUtils

import qualified Luna.Syntax.Builder        as Builder
import           Luna.Syntax.Repr.Graph     (Ref, Node, Edge)
import           Luna.Syntax.AST.Term       (Var(..), App(..), Blank(..), Accessor(..), Unify(..), Draft, Val)
import qualified Luna.Syntax.AST.Lit        as Lit

type VarMap = Map (Ref Node) NodeId

buildGraph :: Command Graph API.Graph
buildGraph = API.Graph <$> buildNodes <*> buildConnections

buildNodes :: Command Graph [API.Node]
buildNodes = do
    allNodeIds <- uses Graph.nodeMapping IntMap.keys
    varMap     <- getVarMap
    mapM (buildNode' varMap) allNodeIds

buildNode :: NodeId -> Command Graph API.Node
buildNode nid = getVarMap >>= flip buildNode' nid

buildNode' :: VarMap -> NodeId -> Command Graph API.Node
buildNode' varMap nodeId = do
    ref   <- GraphUtils.getASTTarget nodeId
    uref  <- GraphUtils.getASTPointer nodeId
    expr  <- zoom Graph.ast $ runASTOp $ Print.printExpression ref
    meta  <- zoom Graph.ast $ AST.readMeta uref
    ports <- buildPorts varMap ref
    let portMap = Map.fromList $ flip fmap ports $ \p@(Port id _ _) -> (id, p)
    return $ API.Node nodeId (Text.pack expr) portMap $ fromMaybe def meta

getDefaultValue :: VarMap -> Ref Node -> ASTOp (Maybe PortDefault)
getDefaultValue varMap ref
    | Map.member ref varMap = return Nothing
    | otherwise             = do
        node <- Builder.readRef ref
        case' (uncoat node) $ do
            match $ \val -> case' (val :: Val (Ref Edge)) $ match $ \lit -> case lit of
                Lit.String s -> return . Just . Constant . StringValue $ Text.unpack $ toText s
                Lit.Int    i -> return . Just . Constant . IntValue    $ i
            match $ \Blank -> return Nothing
            match $ \ANY   -> Print.printExpression ref >>= return . Just . Expression

buildPort :: VarMap -> (PortId, Ref Node) -> ASTOp Port
buildPort varMap (portId, ref) = Port portId (ValueType "Int") <$> getDefaultValue varMap ref

buildPorts :: VarMap -> Ref Node -> Command Graph [Port]
buildPorts varMap ref = zoom Graph.ast $ runASTOp $ do
    selfRef  <- maybeToList <$> getSelfNodeRef ref
    args     <- getPositionalNodeRefs ref
    selfPort <- mapM (buildPort varMap) $ zip [InPortId Self] selfRef
    argPorts <- mapM (buildPort varMap) $ zip (InPortId . Arg <$> [0..]) args
    return $ selfPort ++ argPorts ++ [Port (OutPortId All) (ValueType "Int") Nothing]

buildConnections :: Command Graph [(OutPortRef, InPortRef)]
buildConnections = do
    varMap <- getVarMap
    allNodes <- uses Graph.nodeMapping IntMap.keys
    edges <- mapM (getNodeInputs varMap) allNodes
    return $ concat edges

getVarMap :: Command Graph VarMap
getVarMap = do
    allNodes <- uses Graph.nodeMapping IntMap.keys
    vars <- mapM GraphUtils.getASTVar allNodes
    return $ Map.fromList $ zip vars allNodes

getSelfNodeRef :: Ref Node -> ASTOp (Maybe (Ref Node))
getSelfNodeRef nodeRef = do
    node <- Builder.readRef nodeRef
    case' (uncoat node) $ do
        match $ \(Accessor _ t) -> Builder.follow t >>= return . Just
        match $ \(App t _)      -> Builder.follow t >>= getSelfNodeRef
        match $ \ANY            -> return Nothing

getPositionalNodeRefs :: Ref Node -> ASTOp [Ref Node]
getPositionalNodeRefs nodeRef = do
    node <- Builder.readRef nodeRef
    case' (uncoat node) $ do
        match $ \(App _ args) -> ASTBuilder.unpackArguments args
        match $ \ANY          -> return []

getNodeInputs :: VarMap -> NodeId -> Command Graph [(OutPortRef, InPortRef)]
getNodeInputs varMap nodeId = do
    ref     <- GraphUtils.getASTTarget nodeId
    selfMay <- zoom Graph.ast $ runASTOp $ getSelfNodeRef ref
    let selfNodeMay = selfMay >>= flip Map.lookup varMap
        selfConnMay = (,) <$> (OutPortRef <$> selfNodeMay <*> Just All)
                          <*> (Just $ InPortRef nodeId Self)

    args <- zoom Graph.ast $ runASTOp $ getPositionalNodeRefs ref
    let nodeMays = flip Map.lookup varMap <$> args
        withInd  = zip nodeMays [0..]
        onlyExt  = catMaybes $ (\(n, i) -> (,) <$> n <*> Just i) <$> withInd
        conns    = flip fmap onlyExt $ \(n, i) -> (OutPortRef n All, InPortRef nodeId (Arg i))
    return $ (maybeToList selfConnMay) ++ conns
