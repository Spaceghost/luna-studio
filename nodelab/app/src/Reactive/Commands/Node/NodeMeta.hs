module Reactive.Commands.Node.NodeMeta
    ( updateNodeMeta
    ) where

import qualified Data.Text.Lazy               as Text
import           Utils.PreludePlus
import           Utils.Vector

import           Empire.API.Data.Node         (NodeId)
import qualified Empire.API.Data.Node         as Node
import           Empire.API.Data.NodeMeta     (NodeMeta (..))
import qualified Empire.API.Data.NodeMeta     as NodeMeta

import qualified Object.Widget.Node           as Model

import           Reactive.Commands.Command    (Command, performIO)
import           Reactive.Commands.Graph      (nodeIdToWidgetId, updateConnections)
import qualified Reactive.Commands.UIRegistry as UICmd
import           Reactive.State.Global        (inRegistry)
import qualified Reactive.State.Global        as Global
import qualified Reactive.State.Graph         as Graph

updateNodeMeta :: NodeId -> NodeMeta -> Command Global.State ()
updateNodeMeta nodeId meta = do
    Global.graph . Graph.nodesMap . ix nodeId . Node.nodeMeta .= meta
    inRegistry $ do
        widgetId <- nodeIdToWidgetId nodeId
        withJust widgetId $ \widgetId -> do
            UICmd.update widgetId $ Model.isRequired .~ (meta ^. NodeMeta.isRequired)
            UICmd.move   widgetId $ fromTuple $  meta ^. NodeMeta.position
    updateConnections
