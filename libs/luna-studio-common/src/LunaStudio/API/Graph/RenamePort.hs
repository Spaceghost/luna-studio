module LunaStudio.API.Graph.RenamePort where

import           Data.Aeson.Types              (ToJSON)
import           Data.Binary                   (Binary)
import qualified LunaStudio.API.Graph.Request  as G
import           LunaStudio.API.Graph.Result   (Result)
import qualified LunaStudio.API.Request        as R
import qualified LunaStudio.API.Response       as Response
import qualified LunaStudio.API.Topic          as T
import           LunaStudio.Data.GraphLocation (GraphLocation)
import           LunaStudio.Data.PortRef       (OutPortRef)
import           Prologue


data Request = Request { _location :: GraphLocation
                       , _portRef  :: OutPortRef
                       , _name     :: Text
                       } deriving (Eq, Generic, Show)

data Inverse = Inverse { _prevName :: Text
                       } deriving (Eq, Generic, Show)

makeLenses ''Request
makeLenses ''Inverse
instance Binary Request
instance NFData Request
instance ToJSON Request
instance Binary Inverse
instance NFData Inverse
instance ToJSON Inverse
instance G.GraphRequest Request where location = location


type Response = Response.Response Request Inverse Result
instance Response.ResponseResult Request Inverse Result

topicPrefix :: T.Topic
topicPrefix = "empire.graph.node.renamePort"
instance T.MessageTopic (R.Request Request) where topic _ = topicPrefix <> T.request
instance T.MessageTopic Response            where topic _ = topicPrefix <> T.response
