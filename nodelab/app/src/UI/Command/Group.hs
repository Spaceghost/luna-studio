{-# LANGUAGE Rank2Types #-}

module UI.Command.Group where

import           Utils.PreludePlus
import           Utils.Vector
import           Control.Monad (forM, foldM)

import           Object.UITypes
import           Object.Widget
import qualified Reactive.State.Global           as Global
import           Reactive.Commands.Command       (Command, performIO)

import           Reactive.State.UIRegistry     (sceneInterfaceId, sceneGraphId, addHandler)
import qualified Reactive.State.UIRegistry     as UIRegistry
import qualified Reactive.Commands.UIRegistry  as UICmd


getFarEdge :: Getter (Vector2 Double) Double -> WidgetId -> Command UIRegistry.State Double
getFarEdge getter id = do
    offset <- UICmd.get' id $ widgetPosition . getter
    size   <- UICmd.get' id $ widgetSize     . getter
    return $ offset + size

updateSize :: WidgetId -> Command UIRegistry.State ()
updateSize id = do
    widgets <- UICmd.children id
    widths  <- mapM (getFarEdge x) widgets
    heights <- mapM (getFarEdge y) widgets

    UIRegistry.widgets . ix id . widget . widgetSize .= Vector2 (maximum widths) (maximum heights)
