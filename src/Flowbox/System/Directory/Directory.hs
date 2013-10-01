-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.System.Directory.Directory (
    copyDirectoryRecursive,
    copyFile,
    createDirectory,
    createDirectoryIfMissing,
    doesFileExist,
    doesDirectoryExist,
    getDirectoryRecursive,
    removeDirectoryRecursive,
    removeFile,
    renameDirectory,
    renameFile,
    touchFile,

    module System.Directory,
) where

import           Control.Applicative      
import qualified Data.List              as List
import qualified System.Directory       as Directory
import           System.Directory       hiding (copyFile, createDirectory, createDirectoryIfMissing, doesDirectoryExist, doesFileExist, renameDirectory, renameFile, removeDirectoryRecursive, removeFile)
import qualified System.IO              as IO

import           Flowbox.Prelude          
import qualified Flowbox.System.UniPath as UniPath
import           Flowbox.System.UniPath   (UniPath)



copyDirectoryRecursive :: UniPath -> UniPath -> IO ()
copyDirectoryRecursive usrc udst = do
    let 
        copyContent :: UniPath -> UniPath -> String -> IO ()
        copyContent s d name = do 
            let sname = UniPath.append name s 
                dname = UniPath.append name d
            isDir <- doesDirectoryExist sname
            if isDir 
                then do createDirectory dname
                        contents <- filter (`notElem` [".", ".."]) <$> Directory.getDirectoryContents (UniPath.toUnixString sname)
                        mapM_ (copyContent sname dname) contents  
                else do
                    isFile <- doesFileExist sname
                    if isFile 
                        then copyFile sname dname
                        else fail $ "Failed to copy '" ++ (UniPath.toUnixString sname) ++  "' not implmented record type."

    src <- UniPath.expand usrc
    dst <- UniPath.expand udst
    let base     = UniPath.basePath src
        fileName = UniPath.fileName src
    copyContent base dst fileName
    

copyFile :: UniPath -> UniPath -> IO ()
copyFile usrc udst = do
    src <- UniPath.toUnixString <$> UniPath.expand usrc
    dst <- UniPath.toUnixString <$> UniPath.expand udst
    Directory.copyFile src dst


createDirectory :: UniPath -> IO()
createDirectory upath = do
    path <- UniPath.toUnixString <$> UniPath.expand upath
    Directory.createDirectory path


createDirectoryIfMissing :: Bool -> UniPath -> IO ()
createDirectoryIfMissing create_parents upath = do
    path <- UniPath.toUnixString <$> UniPath.expand upath
    Directory.createDirectoryIfMissing create_parents path


doesDirectoryExist :: UniPath -> IO Bool
doesDirectoryExist upath = do
    path <- UniPath.toUnixString <$> UniPath.expand upath
    Directory.doesDirectoryExist path


doesFileExist :: UniPath -> IO Bool
doesFileExist upath = do
    path <- UniPath.toUnixString <$> UniPath.expand upath
    Directory.doesFileExist path


getDirectoryRecursive :: UniPath -> IO [UniPath]
getDirectoryRecursive upath = do
    path  <- UniPath.expand upath
    isDir <- doesDirectoryExist path
    if isDir
        then do paths <- Directory.getDirectoryContents $ UniPath.toUnixString path
                let filtered = filter (/= ".") $ filter (/= "..") paths
                    upaths = map (\a -> UniPath.append a path) filtered
                children <- mapM getDirectoryRecursive upaths
                return $ List.concat children
        else return [path]


removeDirectoryRecursive :: UniPath -> IO ()
removeDirectoryRecursive upath = do
    path <- UniPath.toUnixString <$> UniPath.expand upath
    Directory.removeDirectoryRecursive path


removeFile :: UniPath -> IO ()
removeFile upath = do
    path <- UniPath.toUnixString <$> UniPath.expand upath
    Directory.removeFile path


renameDirectory :: UniPath -> UniPath -> IO ()
renameDirectory usrc udst = do
    src <- UniPath.toUnixString <$> UniPath.expand usrc
    dst <- UniPath.toUnixString <$> UniPath.expand udst
    Directory.renameDirectory src dst


renameFile :: UniPath -> UniPath -> IO ()
renameFile usrc udst = do
    src <- UniPath.toUnixString <$> UniPath.expand usrc
    dst <- UniPath.toUnixString <$> UniPath.expand udst
    Directory.renameFile src dst


touchFile :: UniPath -> IO ()
touchFile upath = do
    path <- UniPath.toUnixString <$> UniPath.expand upath
    IO.writeFile path ""