---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}

module Main where

import Database.PostgreSQL.Simple as PSQL

import qualified Flowbox.AWS.User.Database.Database  as Database
import qualified Flowbox.AWS.User.Password           as Password
import           Flowbox.AWS.User.User               (User (User))
import           Flowbox.Prelude
import qualified Flowbox.System.Console.ASCIISpinner as Spinner



main :: IO ()
main = do
    putStr "connecting "
    db <- Spinner.runWithSpinner $ Database.mk
            $ PSQL.ConnectInfo "mydbinstance2.cn1bxyb5bfdl.eu-west-1.rds.amazonaws.com"
                               5432
                               "test"
                               "kozatest123"
                               "flowbox"
    putStrLn "creating "
    Database.create db
    putStrLn "adding users "
    Database.addUser db $ User 0 "stefan" (Password.mk "000" "ala123") 100
    Database.addUser db $ User 0 "zenon"  (Password.mk "111" "ala123") 200
    putStrLn "getting users "
    (Just u1) <- Database.getUser db "stefan"
    (Just u2) <- Database.getUser db "zenon"
    Nothing   <- Database.getUser db "mietek"
    print u1
    print u2

