{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-missing-fields #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}

-----------------------------------------------------------------
-- Autogenerated by Thrift Compiler (0.9.0)                      --
--                                                             --
-- DO NOT EDIT UNLESS YOU ARE SURE YOU KNOW WHAT YOU ARE DOING --
-----------------------------------------------------------------

module Batch_Iface where
import Prelude ( Bool(..), Enum, Double, String, Maybe(..),
                 Eq, Show, Ord,
                 return, length, IO, fromIntegral, fromEnum, toEnum,
                 (.), (&&), (||), (==), (++), ($), (-) )

import Control.Exception
import Data.ByteString.Lazy
import Data.Hashable
import Data.Int
import Data.Text.Lazy ( Text )
import qualified Data.Text.Lazy as TL
import Data.Typeable ( Typeable )
import qualified Data.HashMap.Strict as Map
import qualified Data.HashSet as Set
import qualified Data.Vector as Vector

import Thrift
import Thrift.Types ()

import qualified Graphview_Types
import qualified Projects_Types
import qualified Attrs_Types
import qualified Defs_Types
import qualified Graph_Types
import qualified Libs_Types
import qualified Types_Types


import Batch_Types

class Batch_Iface a where
  projects :: a -> IO (Vector.Vector Projects_Types.Project)
  createProject :: a -> Maybe Projects_Types.Project -> IO ()
  openProject :: a -> Maybe Text -> IO Projects_Types.Project
  closeProject :: a -> Maybe Int32 -> IO ()
  storeProject :: a -> Maybe Int32 -> IO ()
  setActiveProject :: a -> Maybe Int32 -> IO ()
  libraries :: a -> IO (Vector.Vector Libs_Types.Library)
  createLibrary :: a -> Maybe Libs_Types.Library -> IO Libs_Types.Library
  loadLibrary :: a -> Maybe Text -> IO Libs_Types.Library
  unloadLibrary :: a -> Maybe Int32 -> IO ()
  storeLibrary :: a -> Maybe Int32 -> IO ()
  buildLibrary :: a -> Maybe Int32 -> IO ()
  libraryRootDef :: a -> Maybe Int32 -> IO Defs_Types.Definition
  defsGraph :: a -> Maybe Int32 -> IO Defs_Types.DefsGraph
  newDefinition :: a -> Maybe Types_Types.Type -> Maybe (Vector.Vector Defs_Types.Import) -> Maybe Attrs_Types.Flags -> Maybe Attrs_Types.Attributes -> IO Defs_Types.Definition
  addDefinition :: a -> Maybe Defs_Types.Definition -> Maybe Int32 -> Maybe Int32 -> IO Defs_Types.Definition
  updateDefinition :: a -> Maybe Defs_Types.Definition -> Maybe Int32 -> IO ()
  removeDefinition :: a -> Maybe Int32 -> Maybe Int32 -> IO ()
  definitionChildren :: a -> Maybe Int32 -> Maybe Int32 -> IO (Vector.Vector Defs_Types.Definition)
  definitionParent :: a -> Maybe Int32 -> Maybe Int32 -> IO Defs_Types.Definition
  newTypeModule :: a -> Maybe Text -> IO Types_Types.Type
  newTypeClass :: a -> Maybe Text -> Maybe (Vector.Vector Text) -> Maybe (Vector.Vector Types_Types.Type) -> IO Types_Types.Type
  newTypeFunction :: a -> Maybe Text -> Maybe Types_Types.Type -> Maybe Types_Types.Type -> IO Types_Types.Type
  newTypeUdefined :: a -> IO Types_Types.Type
  newTypeNamed :: a -> Maybe Text -> Maybe Types_Types.Type -> IO Types_Types.Type
  newTypeVariable :: a -> Maybe Text -> IO Types_Types.Type
  newTypeList :: a -> Maybe Types_Types.Type -> IO Types_Types.Type
  newTypeTuple :: a -> Maybe (Vector.Vector Types_Types.Type) -> IO Types_Types.Type
  nodesGraph :: a -> Maybe Int32 -> Maybe Int32 -> IO Graphview_Types.GraphView
  addNode :: a -> Maybe Graph_Types.Node -> Maybe Int32 -> Maybe Int32 -> IO Graph_Types.Node
  updateNode :: a -> Maybe Graph_Types.Node -> Maybe Int32 -> Maybe Int32 -> IO ()
  removeNode :: a -> Maybe Graph_Types.Node -> Maybe Int32 -> Maybe Int32 -> IO ()
  connect :: a -> Maybe Graph_Types.Node -> Maybe (Vector.Vector Int32) -> Maybe Graph_Types.Node -> Maybe Int32 -> Maybe Int32 -> Maybe Int32 -> IO ()
  disconnect :: a -> Maybe Graph_Types.Node -> Maybe (Vector.Vector Int32) -> Maybe Graph_Types.Node -> Maybe Int32 -> Maybe Int32 -> Maybe Int32 -> IO ()
  ping :: a -> IO ()
