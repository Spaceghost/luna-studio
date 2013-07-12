---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Luna.NodeDef(
NodeDef(..),
empty,
noPorts
) where

import           Luna.Common(NodeDef(..))
import qualified Luna.Graph as Graph

empty :: NodeDef
empty = NodeDef noPorts noPorts [] Graph.empty 0 --FIXME[PM] defaultLibrary = ?

noPorts :: [String]
noPorts = []
