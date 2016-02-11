module UI.Instances (
    module X
) where

import           Object.Widget.Button             as X (Button)
import           Object.Widget.Choice.RadioButton as X (RadioButton)
import           Object.Widget.Connection         as X (Connection,
                                                        CurrentConnection)
import           Object.Widget.Group              as X (Group)
import           Object.Widget.Label              as X (Label)
import           Object.Widget.LabeledTextBox     as X (LabeledTextBox)
import           Object.Widget.List               as X (List)
import           Object.Widget.Node               as X (Node, PendingNode)
import           Object.Widget.Number.Continuous  as X (ContinuousNumber)
import           Object.Widget.Number.Discrete    as X (DiscreteNumber)
import           Object.Widget.Port               as X (Port)
import           Object.Widget.Slider.Continuous  as X (ContinuousSlider)
import           Object.Widget.Slider.Discrete    as X (DiscreteSlider)
import           Object.Widget.TextBox            as X (TextBox)
import           Object.Widget.Toggle             as X (Toggle)
import           Object.Widget.Plots.ScatterPlot  as X (ScatterPlot)

import           UI.Widget.Button                 as X ()
import           UI.Widget.Choice                 as X ()
import           UI.Widget.Choice.RadioButton     as X ()
import           UI.Widget.Connection             as X ()
import           UI.Widget.Group                  as X ()
import           UI.Widget.Label                  as X ()
import           UI.Widget.LabeledTextBox         as X ()
import           UI.Widget.List                   as X ()
import           UI.Widget.List                   as X ()
import           UI.Widget.Node                   as X ()
import           UI.Widget.Number.Continuous      as X ()
import           UI.Widget.Number.Discrete        as X ()
import           UI.Widget.Port                   as X ()
import           UI.Widget.Slider                 as X ()
import           UI.Widget.Slider.Continuous      as X ()
import           UI.Widget.Slider.Discrete        as X ()
import           UI.Widget.TextBox                as X ()
import           UI.Widget.Toggle                 as X ()
import           UI.Widget.Plots.ScatterPlot      as X ()

-- import UI.Handlers.Node                   as X ()
-- import UI.Handlers.Slider                 as X ()
-- import UI.W.Connection             as X ()
-- import UI.Handlers.Port                   as X ()
import           UI.Handlers.Choice               as X ()
import           UI.Handlers.Choice.RadioButton   as X ()
import           UI.Handlers.LabeledTextBox       as X ()
import           UI.Handlers.Number.Continuous    as X ()
import           UI.Handlers.Number.Discrete      as X ()
import           UI.Handlers.Slider.Continuous    as X ()
import           UI.Handlers.Slider.Discrete      as X ()
import           UI.Handlers.TextBox              as X ()
import           UI.Handlers.Toggle               as X ()
import           UI.Handlers.Group                as X ()
import           UI.Handlers.Button               as X ()
import           UI.Handlers.List                 as X ()
-- import UI.Handlers.Label                  as X ()
import           UI.Handlers.Node                 as X ()