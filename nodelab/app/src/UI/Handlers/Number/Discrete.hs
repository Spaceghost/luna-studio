module UI.Handlers.Number.Discrete where

import           Utils.PreludePlus

import           Data.HMap.Lazy                (HTMap, TypeKey (..))
import qualified Data.Text.Lazy                as Text
import           Data.Text.Lazy.Read           (signed, decimal)
import           Utils.Vector

import qualified Event.Mouse                     as Mouse
import           Object.Widget                 (DblClickHandler, DragEndHandler, DragMoveHandler, KeyUpHandler,
                                                MousePressedHandler, UIHandlers, WidgetId, currentPos, dblClick,
                                                dragEnd, dragMove, keyMods, keyUp, mousePressed, startPos,
                                                CompositeWidget, createWidget, updateWidget, ResizableWidget, resizeWidget)
import qualified Object.Widget.Number.Discrete as Model
import qualified Object.Widget.TextBox         as TextBox
import           Reactive.Commands.Command     (Command)
import qualified Reactive.Commands.UIRegistry  as UICmd
import           Reactive.State.Global         (inRegistry)
import qualified Reactive.State.Global         as Global
import           Reactive.State.UIRegistry     (addHandler)
import qualified Reactive.State.UIRegistry     as UIRegistry

import           UI.Generic                    (startDrag)
import           UI.Handlers.Generic           (ValueChangedHandler (..), triggerValueChanged)
import qualified UI.Handlers.TextBox           as TextBox
import           UI.Widget.Number              (keyModMult)
import           UI.Widget.Number.Discrete     ()

isEnabled :: WidgetId -> Command Global.State Bool
isEnabled id = inRegistry $ UICmd.get id Model.enabled

bumpValue :: Int -> WidgetId -> Command Global.State ()
bumpValue amount id = do
    widget <- zoom Global.uiRegistry $ UICmd.update id (Model.value +~ amount)
    triggerValueChanged (widget ^. Model.value) id

setValue :: WidgetId -> Int -> Command UIRegistry.State ()
setValue id val = do
    UICmd.update_ id $ Model.value .~ val
    (tbId:_) <- UICmd.children id
    UICmd.update_ tbId $ TextBox.value .~ (Text.pack $ show $ val)

keyUpHandler :: KeyUpHandler Global.State
keyUpHandler 'Q' _ _ id = bumpValue (-1) id
keyUpHandler 'W' _ _ id = bumpValue ( 1) id
keyUpHandler _   _ _ _  = return ()

startSliderDrag :: MousePressedHandler Global.State
startSliderDrag evt _ id = do
    enabled <- isEnabled id
    when (enabled && (evt ^. Mouse.button == Mouse.LeftButton)) $ do
        value <- inRegistry $ UICmd.get id Model.value
        inRegistry $ UICmd.update_ id $ Model.dragStartValue .~ (Just value)
        startDrag evt id

dragHandler :: DragMoveHandler Global.State
dragHandler ds _ id = do
    enabled <- isEnabled id
    when enabled $ do
        startValue <- inRegistry $ UICmd.get id Model.dragStartValue
        forM_ startValue $ \startValue -> do
            widget <- inRegistry $ UICmd.lookup id
            let width     = widget ^. Model.size . x
                diff      = ds ^. currentPos - ds ^. startPos
                deltaNorm = if (abs $ diff ^. x) > (abs $ diff ^. y) then  diff ^. x /  divider
                                                                     else -diff ^. y / (divider * 10.0)
                divider   = keyModMult $ ds ^. keyMods
                delta     = round $ deltaNorm
            inRegistry $ setValue id (startValue + delta)

dragEndHandler :: DragEndHandler Global.State
dragEndHandler _ _ id = do
    enabled <- isEnabled id
    when enabled $ do
        value      <- inRegistry $ UICmd.get id Model.value
        startValue <- inRegistry $ UICmd.get id Model.dragStartValue
        inRegistry $ UICmd.update_ id $ Model.dragStartValue .~ Nothing
        let startVal = fromMaybe value startValue
        when (startVal /= value) $ triggerValueChanged value id

dblClickHandler :: DblClickHandler Global.State
dblClickHandler _ _ id = do
    (tbId:_) <- inRegistry $ UICmd.children id
    UICmd.takeFocus tbId
    inRegistry $ UICmd.update_ tbId $ TextBox.isEditing .~ True

widgetHandlers :: UIHandlers Global.State
widgetHandlers = def & keyUp        .~ keyUpHandler
                     & mousePressed .~ startSliderDrag
                     & dragMove     .~ dragHandler
                     & dragEnd      .~ dragEndHandler
                     & dblClick     .~ dblClickHandler
--

textHandlers :: WidgetId -> HTMap
textHandlers id = addHandler (ValueChangedHandler $ textValueChangedHandler id)
                $ mempty where

textValueChangedHandler :: WidgetId -> Text -> WidgetId -> Command Global.State ()
textValueChangedHandler parent val tbId = do
    let val' = signed decimal val
    case val' of
        Left err        -> inRegistry $ do
            val <- UICmd.get parent $ Model.displayValue
            UICmd.update_ tbId $ TextBox.value .~ (Text.pack $ val)
        Right (val', _) -> do
            oldValue <- inRegistry $ UICmd.get parent Model.value
            when (oldValue /= val') $ do
                inRegistry $ UICmd.update_ parent $ Model.value .~ val'
                triggerValueChanged val' parent

instance CompositeWidget Model.DiscreteNumber where
    createWidget id model = do
        let tx      = (model ^. Model.size . x) / 2.0
            ty      = (model ^. Model.size . y)
            sx      = tx - (model ^. Model.size . y / 2.0)
            textVal = Text.pack $ show $ model ^. Model.value
            textBox = TextBox.create (Vector2 sx ty) textVal TextBox.Right

        tbId <- UICmd.register id textBox $ textHandlers id
        UICmd.moveX tbId tx

    updateWidget id old model = do
        (tbId:_) <- UICmd.children id
        UICmd.update_ tbId $ TextBox.value .~ (Text.pack $ model ^. Model.displayValue)


instance ResizableWidget Model.DiscreteNumber where resizeWidget = TextBox.labeledEditableResize