{-# LANGUAGE OverloadedStrings #-}

module Empire.ASTOps.Parse where

import           Prologue

import           Control.Monad.Error          (throwError)
import           Data.List.Split              (splitOn)

import           Empire.Data.AST              (NodeRef)
import           Empire.ASTOp                 (ASTOp)
import           Empire.ASTOps.Builder        (applyAccessors)
import           Empire.ASTOps.Remove         (safeRemove)

import           Empire.API.Data.DefaultValue (PortDefault (..), Value (..))

import qualified Luna.Syntax.Model.Network.Builder as Builder

import qualified Luna.Parser.Parser as Parser
import qualified Luna.Parser.State  as Parser
import qualified Luna.Parser.Term   as Term

parseExpr :: ASTOp m => String -> m NodeRef
parseExpr s = case parsed of
        Left d          -> throwError $ "Parser error: " <> show d
        Right (bldr, _) -> do
            r     <- bldr
            fixed <- applyAccessors r
            when (fixed /= r) $ safeRemove r
            return fixed
    where
    operatorHotFix = replace "@.+" "@.op+"
                   . replace "@.*" "@.op*"
                   . replace "@./" "@.op/"
                   . replace "@.-" "@.op-"
                   . replace "@.^" "@.op^"
                   $ s
    parsed = Parser.parseString operatorHotFix $ Parser.parseGen Term.partial Parser.defState

parsePortDefault :: ASTOp m => PortDefault -> m NodeRef
parsePortDefault (Expression expr)          = parseExpr expr
parsePortDefault (Constant (IntValue i))    = Builder.int $ fromIntegral i
parsePortDefault (Constant (StringValue s)) = Builder.str s
parsePortDefault (Constant (DoubleValue d)) = Builder.double d
parsePortDefault (Constant (BoolValue b))   = Builder.cons (fromString $ show b) []

replace :: String -> String -> String -> String
replace word with = intercalate with . splitOn word
