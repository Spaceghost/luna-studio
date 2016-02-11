module Empire.API.Data.Node where

import           Data.Binary               (Binary)
import           Data.Map.Lazy             (Map)
import qualified Data.Map.Lazy             as Map
import           Prologue

import           Empire.API.Data.NodeMeta  (NodeMeta)
import qualified Empire.API.Data.NodeMeta  as NodeMeta
import           Empire.API.Data.Port      (Port, PortId)
import qualified Empire.API.Data.Port      as Port
import           Empire.API.Data.ValueType (ValueType (..))

type NodeId = Int

type FunctionType = [String]

data NodeType = ExpressionNode  { _expression :: Text }
              | InputNode       { _inputIx    :: Int  }
              | OutputNode      { _outputIx   :: Int  }
              | FunctionNode    { _functionType :: FunctionType }
              | ModuleNode
              deriving (Show, Eq, Generic)

data Node = Node { _nodeId   :: NodeId
                 , _name     :: Text
                 , _nodeType :: NodeType
                 , _ports    :: Map PortId Port
                 , _nodeMeta :: NodeMeta
                 } deriving (Generic, Typeable, Show, Eq)

makeLenses ''Node
makeLenses ''NodeType

position :: Lens' Node (Double, Double)
position = nodeMeta . NodeMeta.position

instance Binary Node
instance Binary NodeType