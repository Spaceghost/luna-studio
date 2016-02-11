{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE ConstraintKinds #-}

module Empire.ASTOp where

import           Prologue                               hiding (Num)

import           Control.Monad.Error                    (ErrorT, MonadError, runErrorT)
import           Empire.Data.AST                        (AST, ASTEdge, ASTNode, NodeRef, EdgeRef)
import           Empire.API.Data.NodeMeta               (NodeMeta)
import           Empire.Empire                          (Command, Error, empire)
import           Data.Construction                      (Destructor, Unregister)
import           Luna.Syntax.Model.Network.Builder.Self (MonadSelfBuilder)
import           Luna.Syntax.Model.Network.Builder.Type (MonadTypeBuilder)
import           Luna.Syntax.Model.Graph.Builder        (MonadBuilder, Reader, Writer)
import           Luna.Syntax.Model.Graph.Edge           (Connectible)
import           Luna.Syntax.Model.Network.Builder.Term (TermBuilder, NetLayers, NetworkBuilderT, runNetworkBuilderT)
import           Luna.Syntax.Model.Network.Term         (Raw)
import           Luna.Syntax.AST.Term                   (Acc, App, Blank, Unify, Var, Str, Num)
import           Luna.Syntax.Model.Layer                ((:<))

type ASTOp m = ( MonadIO m
               , MonadFix m
               , MonadError Error m
               , Destructor m NodeRef
               , Reader     m ASTNode
               , Reader     m ASTEdge
               , Writer     m ASTNode
               , Writer     m ASTEdge
               , Unregister m EdgeRef
               , TermBuilder Blank m NodeRef
               , TermBuilder Num   m NodeRef
               , TermBuilder Str   m NodeRef
               , TermBuilder Acc   m NodeRef
               , TermBuilder App   m NodeRef
               , TermBuilder Unify m NodeRef
               , TermBuilder Var   m NodeRef
               , Connectible NodeRef NodeRef m
               )

runGraph :: NetworkBuilderT AST m IO => ErrorT Error m a -> AST -> IO (Either Error a, AST)
runGraph cmd g = runNetworkBuilderT g
               $ runErrorT cmd

runASTOp :: NetworkBuilderT AST m IO => ErrorT Error m a -> Command AST a
runASTOp = empire . runGraph