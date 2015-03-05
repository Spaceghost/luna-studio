---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE TemplateHaskell #-}

module Luna.Syntax.Graph.Tag where

import           Flowbox.Prelude
import           Luna.Syntax.Decl                (LDecl)
import           Luna.Syntax.Enum                (Enumerated (..), ID)
import qualified Luna.Syntax.Enum                as Enum
import           Luna.Syntax.Expr                (LExpr)
import qualified Luna.Syntax.Graph.Node          as Node
import           Luna.Syntax.Graph.Node.Position (Position)



data Tag = Empty { _idTag :: ID }
         | Node  { _idTag    :: ID
                 , _nodeID   :: Node.ID
                 , _position :: Position
                 } deriving (Show)


makeLenses ''Tag


mkNode :: Node.ID -> Tag -> Tag
mkNode nodeID' tag = Node (Enum.id tag) nodeID' def


instance Enumerated Tag where
    id = view idTag
    tag = Empty


type TExpr v = LExpr Tag v
type TDecl v = LDecl Tag (TExpr v)
