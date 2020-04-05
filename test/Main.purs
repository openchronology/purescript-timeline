module Test.Main where

import Timeline.Data (TimeSpan, Event, TimelineChild, Timeline, TimeScale, TimeSpace, TimeSpaceDecided)

import Prelude
import Data.Maybe (Maybe (..))
import Data.Either (Either (Right))
import Data.Generic.Rep (class Generic)
import Data.Argonaut (class EncodeJson, class DecodeJson, encodeJson, decodeJson)
import Data.ArrayBuffer.Class
  ( class EncodeArrayBuffer, class DecodeArrayBuffer, class DynamicByteLength
  , encodeArrayBuffer, decodeArrayBuffer)
import Data.ArrayBuffer.Class.Types (Float64BE (..))
import Data.Identity (Identity)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Console (log)
import Effect.Class (liftEffect)
import Effect.Unsafe (unsafePerformEffect)
import Test.QuickCheck (class Arbitrary, arbitrary, quickCheck)
import Test.Spec (describe, it, SpecT)
import Test.Spec.Runner (runSpec', defaultConfig)
import Test.Spec.Reporter.Console (consoleReporter)
import Type.Proxy (Proxy (..))

main :: Effect Unit
main = launchAff_ $ runSpec' (defaultConfig {timeout = Nothing}) [consoleReporter] tests

tests :: SpecT Aff Unit Identity Unit
tests = do
  describe "Json" do
    jsonTest "TimeSpan" (Proxy :: Proxy (TimeSpan Number))
    jsonTest "Event" (Proxy :: Proxy (Event Number))
    jsonTest "TimelineChild" (Proxy :: Proxy (TimelineChild Number))
    jsonTest "Timeline" (Proxy :: Proxy (Timeline Number))
    jsonTest "TimeScale" (Proxy :: Proxy (TimeScale Number))
    jsonTest "TimeSpace" (Proxy :: Proxy (TimeSpace Number))
    jsonTest "TimeSpaceDecided" (Proxy :: Proxy TimeSpaceDecided)
  describe "Binary" do
    binaryTest "TimeSpan" (Proxy :: Proxy (TimeSpan BinaryFloat))
    binaryTest "Event" (Proxy :: Proxy (Event BinaryFloat))
    binaryTest "TimelineChild" (Proxy :: Proxy (TimelineChild BinaryFloat))
    binaryTest "Timeline" (Proxy :: Proxy (Timeline BinaryFloat))
    binaryTest "TimeScale" (Proxy :: Proxy (TimeScale BinaryFloat))
    binaryTest "TimeSpace" (Proxy :: Proxy (TimeSpace BinaryFloat))
    binaryTest "TimeSpaceDecided" (Proxy :: Proxy TimeSpaceDecided)
  where
    jsonTest :: forall a
              . Arbitrary a
             => Eq a
             => EncodeJson a
             => DecodeJson a
             => String -> Proxy a -> _
    jsonTest name proxy = it name (liftEffect (quickCheck (jsonIso proxy)))
    binaryTest :: forall a
                . Arbitrary a
               => Eq a
               => EncodeArrayBuffer a
               => DecodeArrayBuffer a
               => DynamicByteLength a
               => String -> Proxy a -> _
    binaryTest name proxy = it name (liftEffect (quickCheck (binaryIso proxy)))


jsonIso :: forall a
         . Eq a
        => EncodeJson a
        => DecodeJson a
        => Proxy a -> a -> Boolean
jsonIso Proxy x = decodeJson (encodeJson x) == Right x


binaryIso :: forall a
           . Eq a
          => EncodeArrayBuffer a
          => DecodeArrayBuffer a
          => DynamicByteLength a
          => Proxy a -> a -> Boolean
binaryIso Proxy x = unsafePerformEffect do
  buf <- encodeArrayBuffer x
  mY <- decodeArrayBuffer buf
  pure (mY == Just x)


newtype BinaryFloat = BinaryFloat Float64BE
derive instance genericBinaryFloat :: Generic BinaryFloat _
derive newtype instance eqBinaryFloat :: Eq BinaryFloat
derive newtype instance ordBinaryFloat :: Ord BinaryFloat
derive newtype instance showBinaryFloat :: Show BinaryFloat
derive newtype instance encodeArrayBufferBinaryFloat :: EncodeArrayBuffer BinaryFloat
derive newtype instance decodeArrayBufferBinaryFloat :: DecodeArrayBuffer BinaryFloat
derive newtype instance dynamicByteLengthBinaryFloat :: DynamicByteLength BinaryFloat
instance arbitraryBinaryFloat :: Arbitrary BinaryFloat where
  arbitrary = BinaryFloat <<< Float64BE <$> arbitrary
