---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

{-# OPTIONS_GHC -fno-warn-missing-methods #-}

{-# LANGUAGE DataKinds                 #-}
{-# LANGUAGE DeriveDataTypeable        #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE FlexibleInstances         #-}
{-# LANGUAGE FunctionalDependencies    #-}
{-# LANGUAGE GADTs                     #-}
{-# LANGUAGE IncoherentInstances       #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE OverlappingInstances      #-}
{-# LANGUAGE PolyKinds                 #-}
{-# LANGUAGE TypeFamilies              #-}
{-# LANGUAGE UndecidableInstances      #-}

module Type.Infer where

import           Data.Proxy.Utils
import           Data.Typeable
import           Prelude
import           Unsafe.Coerce

--------------------------------------------------------------------------------
-- Type classes
--------------------------------------------------------------------------------

class InferType a where
    inferType :: Proxy a -> Proxy a
    inferType = undefined

class InferType2 (a::k) (b::k) | a -> b where
    inferType2 :: Proxy a -> Proxy b
    inferType2 = undefined


class BreakInference a b | a -> b where
    breakInference :: a -> b

--instance BreakInference a b <= (a~b) where
--    breakInference a = a

instance BreakInference Int String where
    breakInference = undefined

--------------------------------------------------------------------------------
-- Proxy datatypes
--------------------------------------------------------------------------------

data Id0 = Id0 deriving (Show, Typeable)
data Id1 t1 = Id1 deriving (Show, Typeable)
data Id2 t1 t2 = Id2 deriving (Show, Typeable)
data Id3 t1 t2 t3 = Id3 deriving (Show, Typeable)
data Id4 t1 t2 t3 t4 = Id4 deriving (Show, Typeable)
data Id5 t1 t2 t3 t4 t5 = Id5 deriving (Show, Typeable)


--------------------------------------------------------------------------------
-- Instances
--------------------------------------------------------------------------------

--instance Num a <= InferType2 a a
--instance Monad a <= InferType2 a a

--instance InferType2 Int Int

--instance InferType2 (m a) (m' a') <= (InferType2 m m', InferType2 a a')
--instance InferType2 (a :: *) b <= (b~Id0)
--instance InferType2 (a :: * -> *) b <= (b~Id1)
--instance InferType2 (a :: * -> * -> *) b <= (b~Id2)


instance InferType a => Num a
instance InferType a => Functor a
instance InferType a => Applicative a
instance InferType a => Monad a

instance InferType Int

instance (InferType m, InferType a) => InferType (m a)
instance (a~Id0) => InferType (a :: *)
instance (a~Id1) => InferType (a :: * -> *)
instance (a~Id2) => InferType (a :: * -> * -> *)

--inferTypeBase :: InferType a => a -> a
--inferTypeBase a = inferType $ toProxy a

--c2 :: Monad (m a) => a -> b -> m a b
--c2 = undefined

--instance InferType Foo1
--instance InferType Foo2

--tm _ = 5

--data Foo1 a = Foo1 a deriving (Show, Typeable)
--data Foo2 a b = Foo2 a b deriving (Show, Typeable)

--data Y a = Y a deriving (Show)

type family Testxxx x :: *

type instance Testxxx a = a

--break2 :: a -> Testxxx a
--break2 a = unsafeCoerce a


--main = do
--    let x = 1
--        y = breakInference x
--        --x :: Int
--        --y :: Double
--    print $ typeOf $ inferType $ toProxy $ (return (5))
--    print $ typeOf $ inferType $ toProxy $ (5)
--    print $ typeOf $ inferType $ toProxy $ (Foo1 (return 5))
--    print $ typeOf $ inferType $ toProxy $ (Foo2 (return 5) (return 5))

--    print $ tm $ typeOf $ inferType $ toProxy $ (c2 (5 :: Int) (5 :: Int))

--    print "hello"
