---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances  #-}

module Luna.Data.Serialize.Proto.Conversion.Pat where

import           Control.Applicative
import qualified Data.Map                        as Map
import qualified Text.ProtocolBuffers.Extensions as Extensions

import           Flowbox.Control.Error
import           Flowbox.Prelude
import           Flowbox.Tools.Serialize.Proto.Conversion.Basic
import qualified Generated.Proto.Pat.App                        as GenApp
import qualified Generated.Proto.Pat.Con_                       as GenCon_
import qualified Generated.Proto.Pat.Lit                        as GenLit
import qualified Generated.Proto.Pat.Pat                        as Gen
import qualified Generated.Proto.Pat.Pat.Cls                    as GenCls
import qualified Generated.Proto.Pat.RecWildcard                as GenRecWildcard
import qualified Generated.Proto.Pat.Tuple                      as GenTuple
import qualified Generated.Proto.Pat.Typed                      as GenTyped
import qualified Generated.Proto.Pat.Grouped                      as GenGrouped
import qualified Generated.Proto.Pat.Var                        as GenVar
import qualified Generated.Proto.Pat.Wildcard                   as GenWildcard
import qualified Luna.AST.Common                                as AST
import           Luna.AST.Pat                                   (Pat)
import qualified Luna.AST.Pat                                   as Pat
import           Luna.Data.Serialize.Proto.Conversion.Lit       ()
import           Luna.Data.Serialize.Proto.Conversion.Type      ()



instance Convert Pat Gen.Pat where
    encode p = case p of
        Pat.Var   i name     -> genPat GenCls.Var   i GenVar.ext   $ GenVar.Var     (encodePJ name)
        Pat.Lit   i value    -> genPat GenCls.Lit   i GenLit.ext   $ GenLit.Lit     (encodeJ value)
        Pat.Tuple i items    -> genPat GenCls.Tuple i GenTuple.ext $ GenTuple.Tuple (encodeList items)
        Pat.Con   i name     -> genPat GenCls.Con_  i GenCon_.ext  $ GenCon_.Con_   (encodePJ name)
        Pat.App   i src args -> genPat GenCls.App   i GenApp.ext   $ GenApp.App     (encodeJ src) (encodeList args)
        Pat.Typed i pat cls  -> genPat GenCls.Typed i GenTyped.ext $ GenTyped.Typed (encodeJ pat) (encodeJ cls)
        Pat.Wildcard i       -> genPat GenCls.Wildcard    i GenWildcard.ext    GenWildcard.Wildcard
        Pat.Grouped  i pat   -> genPat GenCls.Grouped     i GenGrouped.ext   $ GenGrouped.Grouped $ encodeJ pat
        Pat.RecWildcard i    -> genPat GenCls.RecWildcard i GenRecWildcard.ext GenRecWildcard.RecWildcard
        where
            genPat :: GenCls.Cls -> AST.ID -> Extensions.Key Maybe Gen.Pat v -> v -> Gen.Pat
            genPat cls i key ext = Extensions.putExt key (Just ext)
                                 $ Gen.Pat cls (encodePJ i) $ Extensions.ExtField Map.empty

    decode p@(Gen.Pat cls mtid _) = do
        i <- decodeP <$> mtid <?> "Failed to decode Pat: 'id' field is missing"
        case cls of
           GenCls.Var      -> do GenVar.Var name <- getExt GenVar.ext "Pat.Var"
                                 Pat.Var i <$> decodePJ name (missing "Pat.Var" "name")
           GenCls.Lit      -> do GenLit.Lit value <- getExt GenLit.ext "Pat.Lit"
                                 Pat.Lit i <$> decodeJ value (missing "Pat.Lit" "value")
           GenCls.Tuple    -> do GenTuple.Tuple items <- getExt GenTuple.ext "Pat.Tuple"
                                 Pat.Tuple i <$> decodeList items
           GenCls.Con_     -> do GenCon_.Con_ name <- getExt GenCon_.ext "Pat.Con_"
                                 Pat.Con i <$> decodePJ name (missing "Pat.Con_" "name")
           GenCls.App      -> do GenApp.App src args <- getExt GenApp.ext "Pat.App"
                                 Pat.App i <$> decodeJ src (missing "Pat.App" "src") <*> decodeList args
           GenCls.Typed    -> do GenTyped.Typed pat type_ <- getExt GenTyped.ext "Pat.Typed"
                                 Pat.Typed i <$> decodeJ pat (missing "Pat.Typed" "pat")
                                             <*> decodeJ type_ (missing "Pat.Typed" "type")
           GenCls.Wildcard -> do GenWildcard.Wildcard <- getExt GenWildcard.ext "Pat.Wildcard"
                                 pure $ Pat.Wildcard i
           GenCls.RecWildcard -> do
                                 GenRecWildcard.RecWildcard <- getExt GenRecWildcard.ext "Pat.RecWildcard"
                                 pure $ Pat.RecWildcard i
      where getExt key datatype = Extensions.getExt key p <?&> missing datatype "extension"
