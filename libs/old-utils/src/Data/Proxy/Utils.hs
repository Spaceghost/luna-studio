---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

{-# LANGUAGE NoMonomorphismRestriction #-}

module Data.Proxy.Utils where

import           Data.Typeable (Proxy (..), Typeable, typeOf)
import           Prelude

toProxy :: a -> Proxy a
toProxy _ = Proxy

proxyTypeName :: Typeable a => Proxy a -> String
proxyTypeName = drop 6 . show . typeOf