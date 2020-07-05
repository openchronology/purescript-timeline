module Timeline.Convert.UISets where

import Timeline.Convert.Errors (PopulateError(..), SynthesizeError(..))
import Timeline.UI.TimeSpace (TimeSpace(..)) as UI
import Timeline.UI.Timeline (Timeline(..)) as UI
import Timeline.UI.Event (Event(..)) as UI
import Timeline.UI.TimeSpan (TimeSpan(..)) as UI
import Timeline.ID.TimeSpace (TimeSpaceID)
import Timeline.ID.Timeline (TimelineID)
import Timeline.ID.Event (EventID)
import Timeline.ID.TimeSpan (TimeSpanID)
import Prelude
import Data.Maybe (Maybe(..))
import Data.Either (Either(..), note)
import Data.Generic.Rep (class Generic)
import Foreign.Object (Object)
import Foreign.Object (union, empty, lookup, insert, member) as Object

-- | Sets for all content, indexed by their UUID
newtype UISets
  = UISets
  { timeSpaces :: Object UI.TimeSpace
  , timelines :: Object UI.Timeline
  , siblingEvents :: Object UI.Event
  , siblingTimeSpans :: Object UI.TimeSpan
  , childEvents :: Object UI.Event
  , childTimeSpans :: Object UI.TimeSpan
  , root :: Maybe TimeSpaceID
  }

-- FIXME may need reference to their parent?
derive instance genericUISets :: Generic UISets _

derive newtype instance showUISets :: Show UISets

instance semigroupUISets :: Semigroup UISets where
  append (UISets x) (UISets y) =
    UISets
      { timeSpaces: Object.union y.timeSpaces x.timeSpaces
      , timelines: Object.union y.timelines x.timelines
      , siblingEvents: Object.union y.siblingEvents x.siblingEvents
      , siblingTimeSpans: Object.union y.siblingTimeSpans x.siblingTimeSpans
      , childEvents: Object.union y.childEvents x.childEvents
      , childTimeSpans: Object.union y.childTimeSpans x.childTimeSpans
      , root:
          case y.root of
            Nothing -> x.root
            _ -> y.root
      }

instance monoidUISets :: Monoid UISets where
  mempty =
    UISets
      { timeSpaces: Object.empty
      , timelines: Object.empty
      , siblingEvents: Object.empty
      , siblingTimeSpans: Object.empty
      , childEvents: Object.empty
      , childTimeSpans: Object.empty
      , root: Nothing
      }

-- | Includes an already flat time space - doesn't verify constituents
addTimeSpace :: UI.TimeSpace -> UISets -> Either PopulateError UISets
addTimeSpace x@(UI.TimeSpace { id }) (UISets xs) =
  let
    id' = show id
  in
    if Object.member id' xs.timeSpaces then
      Left (TimeSpaceExists { timeSpace: x, sets: show (UISets xs) })
    else
      Right
        $ UISets
            xs
              { timeSpaces = Object.insert id' x xs.timeSpaces
              }

-- | Doesn't fail when existing - just re-assigns
addTimeSpace' :: UI.TimeSpace -> UISets -> UISets
addTimeSpace' x@(UI.TimeSpace { id }) (UISets xs) =
  let
    id' = show id
  in
    UISets
      xs
        { timeSpaces = Object.insert id' x xs.timeSpaces
        }

-- | Looks for an already flat time space in the sets
getTimeSpace :: TimeSpaceID -> UISets -> Either SynthesizeError UI.TimeSpace
getTimeSpace id (UISets { timeSpaces }) = note (TimeSpaceDoesntExist id) (Object.lookup (show id) timeSpaces)

-- | Includes an already flat timeline - doesn't verify constituents
addTimeline :: UI.Timeline -> UISets -> Either PopulateError UISets
addTimeline x@(UI.Timeline { id }) (UISets xs) =
  let
    id' = show id
  in
    if Object.member id' xs.timelines then
      Left (TimelineExists x)
    else
      Right
        $ UISets
            xs
              { timelines = Object.insert id' x xs.timelines
              }

addTimeline' :: UI.Timeline -> UISets -> UISets
addTimeline' x@(UI.Timeline { id }) (UISets xs) =
  let
    id' = show id
  in
    UISets
      xs
        { timelines = Object.insert id' x xs.timelines
        }

-- | Looks for an already flat timeline in the sets
getTimeline :: TimelineID -> UISets -> Either SynthesizeError UI.Timeline
getTimeline id (UISets { timelines }) = note (TimelineDoesntExist id) (Object.lookup (show id) timelines)

-- | Includes an already flat event as a sibling - doesn't verify constituents
addSiblingEvent :: UI.Event -> UISets -> Either PopulateError UISets
addSiblingEvent x@(UI.Event { id }) (UISets xs) =
  let
    id' = show id
  in
    if Object.member id' xs.siblingEvents then
      Left (SiblingEventExists x)
    else
      Right
        $ UISets
            xs
              { siblingEvents = Object.insert id' x xs.siblingEvents
              }

addSiblingEvent' :: UI.Event -> UISets -> UISets
addSiblingEvent' x@(UI.Event { id }) (UISets xs) =
  let
    id' = show id
  in
    UISets
      xs
        { siblingEvents = Object.insert id' x xs.siblingEvents
        }

-- | Looks for an already flat event (as a sibling) in the sets
getSiblingEvent :: EventID -> UISets -> Either SynthesizeError UI.Event
getSiblingEvent id (UISets { siblingEvents }) = note (SiblingEventDoesntExist id) (Object.lookup (show id) siblingEvents)

-- | Includes an already flat time span as a sibling - doesn't verify constituents
addSiblingTimeSpan :: UI.TimeSpan -> UISets -> Either PopulateError UISets
addSiblingTimeSpan x@(UI.TimeSpan { id }) (UISets xs) =
  let
    id' = show id
  in
    if Object.member id' xs.siblingTimeSpans then
      Left (SiblingTimeSpanExists x)
    else
      Right
        $ UISets
            xs
              { siblingTimeSpans = Object.insert id' x xs.siblingTimeSpans
              }

addSiblingTimeSpan' :: UI.TimeSpan -> UISets -> UISets
addSiblingTimeSpan' x@(UI.TimeSpan { id }) (UISets xs) =
  let
    id' = show id
  in
    UISets
      xs
        { siblingTimeSpans = Object.insert id' x xs.siblingTimeSpans
        }

-- | Looks for an already flat time span (as a sibling) in the sets
getSiblingTimeSpan :: TimeSpanID -> UISets -> Either SynthesizeError UI.TimeSpan
getSiblingTimeSpan id (UISets { siblingTimeSpans }) = note (SiblingTimeSpanDoesntExist id) (Object.lookup (show id) siblingTimeSpans)

-- | Includes an already flat event as a child - doesn't verify constituents
addChildEvent :: UI.Event -> UISets -> Either PopulateError UISets
addChildEvent x@(UI.Event { id }) (UISets xs) =
  let
    id' = show id
  in
    if Object.member id' xs.childEvents then
      Left (ChildEventExists x)
    else
      Right
        $ UISets
            xs
              { childEvents = Object.insert id' x xs.childEvents
              }

addChildEvent' :: UI.Event -> UISets -> UISets
addChildEvent' x@(UI.Event { id }) (UISets xs) =
  let
    id' = show id
  in
    UISets
      xs
        { childEvents = Object.insert id' x xs.childEvents
        }

-- | Looks for an already flat event (as a child) in the sets
getChildEvent :: EventID -> UISets -> Either SynthesizeError UI.Event
getChildEvent id (UISets { childEvents }) = note (ChildEventDoesntExist id) (Object.lookup (show id) childEvents)

-- | Includes an already flat time span as a child - doesn't verify constituents
addChildTimeSpan :: UI.TimeSpan -> UISets -> Either PopulateError UISets
addChildTimeSpan x@(UI.TimeSpan { id }) (UISets xs) =
  let
    id' = show id
  in
    if Object.member id' xs.childTimeSpans then
      Left (ChildTimeSpanExists x)
    else
      Right
        $ UISets
            xs
              { childTimeSpans = Object.insert id' x xs.childTimeSpans
              }

addChildTimeSpan' :: UI.TimeSpan -> UISets -> UISets
addChildTimeSpan' x@(UI.TimeSpan { id }) (UISets xs) =
  let
    id' = show id
  in
    UISets
      xs
        { childTimeSpans = Object.insert id' x xs.childTimeSpans
        }

-- | Looks for an already flat time span (as a child) in the sets
getChildTimeSpan :: TimeSpanID -> UISets -> Either SynthesizeError UI.TimeSpan
getChildTimeSpan id (UISets { childTimeSpans }) = note (ChildTimeSpanDoesntExists id) (Object.lookup (show id) childTimeSpans)

-- | Assigns the root field of a set
setRoot :: TimeSpaceID -> UISets -> UISets
setRoot id (UISets x) = UISets x { root = Just id }
