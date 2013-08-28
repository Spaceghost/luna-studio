---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------
module Flowbox.Batch.Server.Handlers.Projects (
    projects,

    createProject,
    openProject, 
    closeProject,
    storeProject,
    setActiveProject,
    activeProject
) where


import           Data.Int                                                   
import           Data.IORef                                                 
import qualified Data.Vector                                              as Vector
import           Data.Vector                                                (Vector)
import           Data.Text.Lazy                                             (Text)

import qualified Projects_Types                                           as TProjects
import           Flowbox.Control.Error                                      
import qualified Flowbox.Batch.Batch                                      as Batch
import           Flowbox.Batch.Batch                                        (Batch(..))
import qualified Flowbox.Batch.Handlers.Projects                          as BatchP
import qualified Flowbox.Batch.Project.Project                            as Project
import           Flowbox.Batch.Project.Project                              (Project(..))
import           Flowbox.Batch.Server.Handlers.Common                       (logger, tRunScript)
import           Flowbox.Batch.Tools.Serialize.Thrift.Conversion.Projects   ()
import qualified Flowbox.Luna.Lib.LibManager                              as LibManager
import           Flowbox.System.Log.Logger                                  
import           Flowbox.Tools.Conversion                                   


------ public api -------------------------------------------------

projects :: IORef Batch -> IO (Vector TProjects.Project)
projects batchHandler = do
    logger.info $ "call projects"
    batch <- readIORef batchHandler
    let aprojects       = BatchP.projects batch
        tprojects       = map (fst . encode) aprojects
        tprojectsVector = Vector.fromList tprojects
    return tprojectsVector


createProject :: IORef Batch -> Maybe TProjects.Project -> IO TProjects.Project
createProject batchHandler mtproject = tRunScript $ do
    scriptIO $ logger.info $ "call createProject"
    tproject     <- mtproject <??> "'project' field is missing" 
    (_, project) <- tryRight (decode (tproject, LibManager.empty) :: Either String (Project.ID, Project))
    batch        <- tryReadIORef batchHandler
    let (newBatch, newProject) = BatchP.createProject project batch
    tryWriteIORef batchHandler newBatch
    return $ fst $ encode newProject


openProject :: IORef Batch -> Maybe Text -> IO TProjects.Project
openProject batchHandler mtpath = tRunScript $ do
    scriptIO $ logger.info $ "call openProject"
    upath <- tryGetUniPath mtpath "path"
    batch <- tryReadIORef batchHandler
    (newBatch, (projectID, aproject)) <- scriptIO $ BatchP.openProject upath batch
    tryWriteIORef batchHandler newBatch
    return $ fst $ encode (projectID, aproject)


closeProject :: IORef Batch -> Maybe Int32 -> IO ()
closeProject batchHandler mtprojectID = tRunScript $ do
    scriptIO $ logger.info $ "call closeProject"
    projectID <- tryGetID mtprojectID "projectID"
    batch     <- tryReadIORef batchHandler
    let newBatch = BatchP.closeProject projectID batch
    tryWriteIORef batchHandler newBatch


storeProject :: IORef Batch -> Maybe Int32 -> IO ()
storeProject batchHandler mtprojectID = tRunScript $ do
    scriptIO $ logger.info $ "call storeProject"
    projectID <- tryGetID mtprojectID "projectID"
    batch     <- tryReadIORef batchHandler
    scriptIO $ BatchP.storeProject projectID batch


setActiveProject :: IORef Batch -> Maybe Int32 -> IO ()
setActiveProject batchHandler mtprojectID = tRunScript $ do
    scriptIO $ logger.info $ "call setActiveProject"
    projectID <- tryGetID mtprojectID "projectID"
    batch     <- tryReadIORef batchHandler
    let newBatch = BatchP.setActiveProject projectID batch
    tryWriteIORef batchHandler newBatch


activeProject :: IORef Batch -> IO TProjects.Project
activeProject batchHandler = tRunScript $ do
    scriptIO $ logger.info $ "call activeProject"
    batch   <- tryReadIORef batchHandler
    project <- (BatchP.activeProject batch) <??> "No active project set"
    let projectID = Batch.activeProjectID batch
    return $ fst $ encode (projectID, project)
