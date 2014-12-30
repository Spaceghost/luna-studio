---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

module Flowbox.Graphics.Image.View (
    View,
    Name,
    ChanTree,
    Select,
    get,
    append,
    name,
    channels,
    set,
    empty,
    map,
    remove
) where

import Data.List       as List (foldl')
import Data.List.Split
import Data.Set        hiding (empty, map)

import           Flowbox.Data.MapTree           (MapTree (..))
import qualified Flowbox.Data.MapTree           as MapTree
import           Flowbox.Graphics.Image.Channel (Channel (..))
import qualified Flowbox.Graphics.Image.Channel as Channel
import           Flowbox.Graphics.Image.Error   (Error (..))
import qualified Flowbox.Graphics.Image.Error   as Image
import           Flowbox.Prelude                as P hiding (empty, map, set)



type Name     = String
type ChanTree = ChannelTree Channel.Name Channel
type Select   = Set Name

data View = View { name     :: Name
                 , channels :: ChanTree
                 }
          deriving (Show)

set :: ChanTree -> View -> View
set t (View name _) = View name t

empty :: Name -> View
empty name = View name ChanTree.empty

map :: (Channel -> Channel) -> View -> View
map f v = set (fmap f (channels v)) v

get :: View -> Channel.Name -> Image.Result (Maybe Channel)
get v descriptor = case result of
    Left _    -> Left $ ChannelLookupError descriptor
    Right val -> Right val
    where result = gotoChannel descriptor v >>= ChanTree.get

append :: Channel -> View -> View
append chan v = set (ChanTree.tree result') v
    where result  = List.foldl' go z (init nodes) >>= insert (last nodes) (Just chan) >>= ChanTree.top
          result' = case result of
              Right res -> res
              Left err  -> errorShitWentWrong $ "append (" ++ show err ++ ") "

          go acc p   = let res = acc >>= ChanTree.lookup p in case res of
              Right _ -> res
              Left  _ -> acc >>= ChanTree.append p Nothing >>= ChanTree.lookup p

          insert :: String -> Maybe Channel -> ChanTree.Zipper String Channel -> ChanTree.ZipperResult String Channel
          insert p v' zipper = let res = ChanTree.lookup p zipper in case res of
              Right (ChannelTree _ oldmap, _) -> ChanTree.attach p (ChannelTree v' oldmap) zipper
              Left _ -> ChanTree.append p v' zipper

          z          = ChanTree.zipper $ channels v
          nodes      = splitOn "." descriptor
          descriptor = Channel.name chan

remove :: Name -> View -> Image.Result View
remove name view = case gotoChannel name view of
    Left _    -> Left $ ChannelLookupError name
    Right val -> case ChanTree.delete val of
        Left _     -> Left $ ChannelLookupError "can it really happen?"
        Right tree -> pure $ set (ChanTree.tree $ ChanTree.top' tree) view

gotoChannel :: Name -> View -> ChanTree.ZipperResult Channel.Name Channel
gotoChannel name view = result
    where result        = List.foldl' go startingPoint nodes
          go tree name' = tree >>= ChanTree.lookup name'
          startingPoint = ChanTree.zipper $ channels view
          nodes         = splitOn "." name

mapWithWhitelist :: (Channel -> Channel) -> Channel.Select -> View -> View
mapWithWhitelist f whitelist = map lambda
    where lambda chan = if Channel.name chan `elem` whitelist
                            then f chan
                            else chan

-- == HELPERS == for error reporting

errorShitWentWrong :: String -> a
errorShitWentWrong fun =
  error (thisModule ++ fun ++ ": cosmic radiation caused this function to utterly fail. Blame the monkeys and send us an error report.")

thisModule :: String
thisModule = "Flowbox.Graphics.Image.View."
