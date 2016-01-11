{-# LANGUAGE OverloadedStrings #-}

module Empire.Server.Project where

import           Prologue

import qualified Data.Binary                      as Bin
import           System.Path                      (Path)
import           Control.Monad.State              (StateT, get, put)
import           Data.Map.Strict                  (Map)
import           Data.ByteString                  (ByteString)
import           Data.ByteString.Char8            (unpack)
import           Data.ByteString.Lazy             (fromStrict, toStrict)
import           Data.Text.Lazy                   (Text)
import qualified Data.Text.Lazy                   as Text
import qualified Flowbox.Bus.Data.Flag            as Flag
import qualified Flowbox.Bus.Data.Message         as Message
import qualified Flowbox.Bus.Bus                  as Bus
import           Flowbox.Bus.BusT                 (BusT (..))
import qualified Flowbox.Bus.BusT                 as Bus
import qualified Flowbox.System.Log.Logger        as Logger
import qualified Empire.Env                       as Env
import           Empire.Env                       (Env)
import qualified Empire.Data.Project              as DataProject
import           Empire.Data.AST                  (AST)
import qualified Empire.API.Project.CreateProject as CreateProject
import qualified Empire.API.Project.ListProjects  as ListProjects
import qualified Empire.API.Response              as Response
import qualified Empire.API.Topic                 as Topic
import qualified Empire.Commands.Project          as ProjectCmd
import qualified Empire.Empire                    as Empire
import           Empire.Empire                    (Empire)
import qualified Empire.Server.Server            as Server

logger :: Logger.LoggerIO
logger = Logger.getLoggerIO $(Logger.moduleName)

handleCreateProject :: ByteString -> StateT Env BusT ()
handleCreateProject content = do
    let request = Bin.decode . fromStrict $ content :: CreateProject.Request
    logger Logger.info $ show request
    currentEmpireEnv <- use Env.empireEnv
    logger Logger.info $ show currentEmpireEnv
    (result, newEmpireEnv) <- liftIO $ Empire.runEmpire currentEmpireEnv $ ProjectCmd.createProject
        (request ^. CreateProject.projectName)
        (fromString $ request ^. CreateProject.path)
    case result of
        Left err -> logger Logger.error $ Server.errorMessage ++ err
        Right (projectId, project) -> do
            Env.empireEnv .= newEmpireEnv
            let response = Response.Update request $ CreateProject.Update projectId $ DataProject.toAPI project
            lift $ BusT $ Bus.send Flag.Enable $ Message.Message Topic.createProjectResponse $ toStrict $ Bin.encode response
            return ()

handleListProjects :: ByteString -> StateT Env BusT ()
handleListProjects content = do
    let request = Bin.decode . fromStrict $ content :: ListProjects.Request
    logger Logger.info $ show request
    currentEmpireEnv <- use Env.empireEnv
    logger Logger.info $ show currentEmpireEnv
    (result, newEmpireEnv) <- liftIO $ Empire.runEmpire currentEmpireEnv $ ProjectCmd.listProjects
    case result of
        Left err -> logger Logger.error $ Server.errorMessage ++ err
        Right projectList -> do
            Env.empireEnv .= newEmpireEnv
            let projectListAPI = fmap (\(projectId, project) -> (projectId, DataProject.toAPI project)) projectList
                response = Response.Update request $ ListProjects.Status projectListAPI
            lift $ BusT $ Bus.send Flag.Enable $ Message.Message Topic.listProjectsResponse $ toStrict $ Bin.encode response
            return ()
