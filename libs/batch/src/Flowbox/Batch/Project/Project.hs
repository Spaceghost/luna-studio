---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.Batch.Project.Project(
    Project(..),
	ID,
	empty
) where

import qualified Flowbox.Luna.Core                        as Core
import           Flowbox.Luna.Core                          (Core(..))
import qualified Flowbox.Luna.Network.Attributes          as Attributes
import           Flowbox.Luna.Network.Attributes            (Attributes)
import qualified Flowbox.Luna.System.UniPath              as UniPath
import           Flowbox.Luna.System.UniPath                (UniPath)



data Project = Project { core  :: Core
                       , name  :: String
                       , path  :: UniPath
                       , attrs :: Attributes
                       } deriving(Show)

type ID = Int


empty :: Project
empty = Project Core.empty "" UniPath.empty Attributes.empty