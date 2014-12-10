---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE ConstraintKinds            #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE NoMonomorphismRestriction  #-}

module Luna.Data.Namespace.State where

import           Control.Monad.State (MonadState, get, modify, put)
import qualified Data.IntMap         as IntMap

import           Flowbox.Prelude           hiding (id)
import           Flowbox.System.Log.Logger
import           Luna.ASTNew.AST              (AST, ID)
import qualified Luna.ASTNew.AST              as AST
import           Luna.ASTNew.Expr             (Expr)
import qualified Luna.ASTNew.Expr             as Expr
import           Luna.ASTNew.Lit              (Lit)
import qualified Luna.ASTNew.Lit              as Lit
import           Luna.ASTNew.Module           (Module)
import qualified Luna.ASTNew.Module           as Module
import           Luna.ASTNew.Pat              (Pat)
import qualified Luna.ASTNew.Pat              as Pat
import           Luna.ASTNew.Type             (Type)
import qualified Luna.ASTNew.Type             as Type
import           Luna.Data.AliasInfo       (AliasInfo)
import qualified Luna.Data.AliasInfo       as AliasInfo
import           Luna.Data.Namespace       (Namespace)
import qualified Luna.Data.Namespace       as Namespace
import           Flowbox.System.Log.Logger as L



logger :: LoggerIO
logger = getLoggerIO $(moduleName)


--data VAState = VAState { _info    :: AliasInfo
--                       , _idStack :: [ID]
--                       }
--             deriving (Show)

--makeLenses (''VAState)

type NamespaceMonad m = (MonadState Namespace m, Applicative m)


--getAliasInfo :: NamespaceMonad m => m AliasInfo
getAliasInfo = view Namespace.info <$> get

--getCurrentID :: NamespaceMonad m => m (Maybe ID)
--getCurrentID = do stack <- view idStack <$> get
--                  return $ case stack of
--                      []    -> Nothing
--                      (x:_) -> Just x


scopeID = Namespace.head <$> get


--putAliasInfo :: NamespaceMonad m => AliasInfo -> m ()
putAliasInfo info = modify (Namespace.info .~ info)


--modifyAliasInfo :: NamespaceMonad m => (AliasInfo -> AliasInfo) -> m ()
modifyAliasInfo f = do
    info <- getAliasInfo
    putAliasInfo $ f info



--pushID :: NamespaceMonad m => ID -> m ()
pushID id = modify $ Namespace.pushID id

--popID :: NamespaceMonad m => m ID
popID = do
    (id, ns') <- Namespace.popID <$> get
    put ns'
    return id



--pushID :: NamespaceMonad m => ID -> m ()
--pushID id = modify (idStack %~ (id:))

--popID :: NamespaceMonad m => m ID
--popID = do (id:ids) <- view idStack <$> get
--           modify (idStack .~ ids)
--           return id


--withID :: NamespaceMonad m => ID -> m f -> m f
--withID id f = pushID id *> f <* popID

pushNewScope id = modify $ Namespace.pushNewScope id
pushScope    id = modify $ Namespace.pushScope id

popScope = modify $ Namespace.popScope

withNewScope id p = pushNewScope id *> p <* popScope
withScope    id p = pushScope    id *> p <* popScope


withParentID :: NamespaceMonad m => m f -> m f
withParentID f = do pid <- popID
                    out <- f
                    pushID pid
                    return out

----switchID :: NamespaceMonad m => ID -> m ()
----switchID id = modify (currentID .~ id)

regModule :: NamespaceMonad m => Module a e -> m ()
regModule = undefined -- regElBy AST.Module Module.id

regExpr :: NamespaceMonad m => Expr a v -> m ()
regExpr = undefined -- regElBy AST.Expr Expr.id

regLit :: NamespaceMonad m => Lit -> m ()
regLit = undefined -- regElBy AST.Lit Lit.id

regPat :: NamespaceMonad m => Pat a -> m ()
regPat = undefined -- regElBy AST.Pat Pat.id

regType :: NamespaceMonad m => Type a -> m ()
regType = undefined -- regElBy AST.Type Type.id


regOrphan = modifyAliasInfo .: AliasInfo.regOrphan



--regID :: NamespaceMonad m => ID -> m ()
regID id = do
    mpid <- scopeID
    withJust mpid (\pid -> modifyAliasInfo $ AliasInfo.parent %~ IntMap.insert id pid)



--regVarName :: NamespaceMonad m => ID -> String -> m ()
regVarName = regName AliasInfo.varnames

regParent :: NamespaceMonad m => ID -> m ()
regParent id = do
    scopeID <- scopeID
    withJust scopeID (\pid -> modifyAliasInfo (AliasInfo.parent %~ IntMap.insert id pid))


regAlias :: NamespaceMonad m => ID -> String -> m ()
regAlias ident name = do
    aliasMap  <- view AliasInfo.alias <$> getAliasInfo
    aliasInfo <- getAliasInfo
    aliasInfo' <- withCurrentScopeID_ (\scopeId -> AliasInfo.registerAlias ident name scopeId aliasInfo)
    modify (set (Namespace.info) aliasInfo')


withCurrentScopeID_ :: NamespaceMonad m => (ID -> Maybe a) -> m a
withCurrentScopeID_ action = withCurrentScopeID action >>= maybe (fail "Cannot obtain current scope") return

withCurrentScopeID :: NamespaceMonad m => (ID -> Maybe a) -> m (Maybe a)
withCurrentScopeID action = scopeID >>= maybe (return Nothing) (return . action)


withCurrentScope_ :: NamespaceMonad m => (AliasInfo.Scope -> Maybe a) -> m a
withCurrentScope_ action = withCurrentScope action >>= maybe (fail "Cannot obtain current scope") return


withCurrentScope :: NamespaceMonad m => (AliasInfo.Scope -> Maybe a) -> m (Maybe a)
withCurrentScope action = getCurrentScope >>= maybe (return Nothing) (return . action)


getCurrentScope :: NamespaceMonad m => m (Maybe AliasInfo.Scope)
getCurrentScope = scopeID >>= \case
    Just (currentScopeId :: ID) -> view (AliasInfo.scope . at currentScopeId) <$> getAliasInfo
    Nothing                     -> return Nothing


regTypeName :: NamespaceMonad m => ID -> String -> m ()
regTypeName = regName AliasInfo.typenames


regName lens id name = do
    a    <- getAliasInfo
    mcid <- scopeID
    case mcid of
        Nothing  -> fail "Unable to get current id"
        Just cid -> putAliasInfo a2
            where varRel  = a ^. (AliasInfo.scope . (ix cid))
                  varRel2 = varRel & lens.at name ?~ id
                  a2      = a & AliasInfo.scope.at cid ?~ varRel2


regParentVarName :: NamespaceMonad m => ID -> String -> m ()
regParentVarName = withParentID .: regVarName

bindVar id name = do
    ns <- get
    case Namespace.bindVar id name ns of
        Left _    -> fail $ "Unable to bind variable " ++ name -- FIXME[wd]: nicer error messages
        Right ns' -> put ns'

tryBindVar id name = do
    ns <- get
    case Namespace.bindVar id name ns of
        Left _    -> do let errMsg = "Unable to bind variable " ++ name -- FIXME[wd]: nicer error messages
                        logger L.error errMsg
                        regOrphan id $ AliasInfo.LookupError errMsg 
        Right ns' -> put ns'


--bindVar :: NamespaceMonad m => ID -> String -> m ()
--bindVar id name = do
--    mcid <- getCurrentID
--    withJust mcid (\cid -> modifyAliasInfo (bindVarRec id cid name))


--bindVarRec :: ID -> ID -> String -> AliasInfo -> AliasInfo
--bindVarRec id ctxID name a = case dstIDLookup of
--    Just dstID -> updateAliasMap dstID
--    Nothing    -> case mPid of
--                  Just pid -> bindVarRec id pid name a
--                  Nothing  -> updateInvalidMap $ AliasInfo.LookupError name
--    where dstIDLookup          = varnames ^. at name
--          mPid                 = (a ^. AliasInfo.parent) ^. at ctxID
--          varRel               = a ^. AliasInfo.scope.ix ctxID
--          varnames             = varRel ^. AliasInfo.varnames
--          updateAliasMap val   = a & AliasInfo.alias.at id ?~ val
--          updateInvalidMap val = a & AliasInfo.orphans.at id ?~ val



--------------------------------------------------------------------------
---- Instances
--------------------------------------------------------------------------

--instance Monoid VAState where
--    mempty      = VAState mempty mempty
--    mappend a b = VAState (mappend (a ^. aa)      (b ^. aa))
--                          (mappend (a ^. idStack) (b ^. idStack))
