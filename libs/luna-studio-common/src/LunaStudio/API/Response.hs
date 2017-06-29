{-# LANGUAGE FlexibleContexts       #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
module LunaStudio.API.Response where

import           Data.Binary            (Binary)
import           Data.UUID.Types        (UUID)
import           LunaStudio.API.Request (Request (..))
import           LunaStudio.API.Topic   (MessageTopic)
import           Prologue


data Status a = Ok    { _resultData  :: a }
              | Error { _message     :: String }
              deriving (Eq, Generic, NFData, Show)

makeLenses ''Status
makePrisms ''Status
instance Binary a => Binary (Status a)

data Response req inv res = Response { _requestId :: UUID
                                     , _guiID     :: Maybe UUID
                                     , _request   :: req
                                     , _inverse   :: Status inv
                                     , _status    :: Status res
                                     } deriving (Eq, Generic, NFData, Show)

type SimpleResponse req inv = Response req inv ()


class (MessageTopic (Request req), MessageTopic (Response req inv res), Binary req, Binary inv, Binary res) => ResponseResult req inv res | req -> inv res where
  result :: Request req -> inv -> res -> Response req inv res
  result (Request uuid guiID req) inv payload = Response uuid guiID req (Ok inv) (Ok payload)

  error :: Request req -> Status inv -> String -> Response req inv res
  error  (Request uuid guiID req) inv msg = Response uuid guiID req inv (Error msg)

ok :: (ResponseResult req inv (), MessageTopic (Response req inv ())) => Request req -> inv -> Response req inv ()
ok (Request uuid guiID req) inv = Response uuid guiID req (Ok inv) (Ok ())

makeLenses ''Response

instance (Binary req, Binary res, Binary inv) => Binary (Response req inv res)