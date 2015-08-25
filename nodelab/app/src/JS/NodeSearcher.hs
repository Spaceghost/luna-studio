module JS.NodeSearcher where

import           Utils.PreludePlus


import           GHCJS.Foreign
import           GHCJS.DOM.EventM
import           GHCJS.Types      ( JSRef, JSString )
import           GHCJS.DOM.EventTargetClosures (EventName, unsafeEventName)
import           Data.JSString.Text ( lazyTextFromJSString, lazyTextToJSString )
import qualified Data.JSString as JSString

import           JavaScript.Array ( JSArray )
import qualified JavaScript.Array as JSArray

import qualified Data.Text.Lazy as Text
import           Data.Text.Lazy (Text)

import           Control.Monad.IO.Class ( MonadIO(..) )
import           GHCJS.DOM.Types  ( UIEvent, Window, IsUIEvent, unUIEvent, toUIEvent )



foreign import javascript unsafe "app.createNodeSearcher($1, $2, $3)"
    initNodeSearcher :: JSString -> Int -> Int-> IO ()

foreign import javascript unsafe "app.destroyNodeSearcher()"
    destroyNodeSearcher :: IO ()

foreign import javascript unsafe "$2[\"detail\"][$1]"
    nodesearcher_event_get :: JSString -> JSRef UIEvent -> IO JSString

nsEvent :: EventName Window UIEvent
nsEvent = (unsafeEventName (JSString.pack "ns_event"))

getKey :: (MonadIO m, IsUIEvent self) => String -> self -> m Text
getKey key self = liftIO $ do
    action <-  nodesearcher_event_get (JSString.pack key) (unUIEvent (toUIEvent self))
    return $ lazyTextFromJSString action

getExpression :: (MonadIO m, IsUIEvent self) => self -> m Text
getExpression = getKey "expression"
getAction :: (MonadIO m, IsUIEvent self) => self -> m Text
getAction     = getKey "action"

-- display results

data JSHighlight

foreign import javascript unsafe "app.nodeSearcher().clearResults()"
    nodesearcher_clear_results :: IO ()

foreign import javascript unsafe "app.nodeSearcher().addResult($1, $2, $3, $4, $5)"
    nodesearcher_add_result :: JSString -> JSString -> JSString -> JSRef JSHighlight -> JSString -> IO ()

foreign import javascript unsafe "app.nodeSearcher().addTreeResult($1, $2, $3, $4)"
    nodesearcher_add_tree_result :: JSString -> JSString -> JSString -> JSString -> IO ()

data Highlight = Highlight {start :: Int, len :: Int} deriving (Show, Eq)
data QueryResult = QueryResult {_prefix :: Text, _name :: Text, _fullname :: Text, _highlights :: [Highlight], _tpe :: Text}

displayQueryResult :: QueryResult -> IO ()
displayQueryResult (QueryResult prefix name fullname highlight tpe) = do
    ary <- createJSArray
    mapM_ (pushHighlight ary) highlight
    nodesearcher_add_result (lazyTextToJSString prefix) (lazyTextToJSString name) (lazyTextToJSString fullname) ary (lazyTextToJSString tpe)

displayQueryResults :: [QueryResult] -> IO ()
displayQueryResults results = do
    nodesearcher_clear_results
    mapM_ displayQueryResult results

displayTreeResult :: QueryResult -> IO ()
displayTreeResult (QueryResult prefix name fullname _ tpe ) = do
    nodesearcher_add_tree_result (lazyTextToJSString prefix) (lazyTextToJSString name) (lazyTextToJSString fullname) (lazyTextToJSString tpe)

displayTreeResults :: [QueryResult] -> IO ()
displayTreeResults results = mapM_ displayTreeResult results

foreign import javascript unsafe "[]"
    createJSArray :: IO (JSRef JSHighlight)

foreign import javascript unsafe "$1.push({start: $2, length: $3})"
    pushHighlightJs :: JSRef JSHighlight -> Int -> Int -> IO (JSRef JSHighlight)

pushHighlight :: JSRef JSHighlight -> Highlight -> IO (JSRef JSHighlight)
pushHighlight acc (Highlight start len) = pushHighlightJs acc start len