module Reactive.Commands.Node
    ( renameNode
    ) where

import qualified Data.Text.Lazy            as Text
import           Utils.PreludePlus

import           Empire.API.Data.Node      (NodeId)
import qualified Empire.API.Data.Node      as Node

import qualified Object.Widget.Node            as Model

import           Reactive.Commands.Command (Command, performIO)
import           Reactive.Commands.Graph   (nodeIdToWidgetId)
import qualified Reactive.Commands.UIRegistry as UICmd
import           Reactive.State.Global     (inRegistry)
import qualified Reactive.State.Global     as Global
import qualified Reactive.State.Graph      as Graph


renameNode :: NodeId -> Text -> Command Global.State ()
renameNode nodeId name = do
    Global.graph . Graph.nodesMap . ix nodeId . Node.name .= name
    inRegistry $ do
        widgetId <- nodeIdToWidgetId nodeId

        withJust widgetId $ flip UICmd.update_ $ Model.name .~ name

