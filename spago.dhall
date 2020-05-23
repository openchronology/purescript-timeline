{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "timeline"
, dependencies =
  [ "argonaut"
  , "arraybuffer-class"
  , "indexed-multiset"
  , "console"
  , "effect"
  , "numbers"
  , "prelude"
  , "psci-support"
  , "spec"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}