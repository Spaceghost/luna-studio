module Empire.Data.Graph where

import           Prologue
import qualified Empire.Utils.IdGen     as IdGen
import           Empire.Data.AST        (AST, NodeRef)
import qualified Data.IntMap            as IntMap
import           Data.IntMap            (IntMap)
import           Empire.API.Data.Node   (NodeId)

import           Empire.API.Data.DefaultValue (Value)
import           Luna.Syntax.Model.Network.Builder (star, runNetworkBuilderT)

data Graph = Graph { _ast         :: AST
                   , _tcAST       :: AST
                   , _nodeMapping :: IntMap NodeRef
                   , _valueCache  :: IntMap (Maybe Value)
                   } deriving (Show)

makeLenses ''Graph

instance Default Graph where
    def = Graph defaultAST defaultAST def def

nextNodeId :: Graph -> NodeId
nextNodeId graph = IdGen.nextId $ graph ^. nodeMapping

defaultAST :: AST
defaultAST = snd $ (runIdentity $ runNetworkBuilderT def $ star :: (NodeRef, AST))
