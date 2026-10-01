-- Dhall 23.x (standard) — syntax showcase
-- ── Comments ──
-- Line comment. TODO: split into modules. FIXME: tighten the types.
{- Block comment
   {- nested block comment -}
   still a comment -}

-- ── Literals ──
let naturals = [ 0, 42, 1_000_000, 0xFF, 0b1010 ]
let integers = [ +5, -3, +0, -0x1F ]
let doubles = [ 3.14159, -2.5, 6.02e23, 1.5e-10, +1.0, NaN, Infinity, -Infinity ]
let booleans = [ True, False ]
let plain = "Warehouse \"north\"\t\n é \u{1F4E6} \$ \\ \/ \b \f \r"
let interpolated = "Total: ${Natural/show 42} items in ${plain}"
let multi =
      ''
      Multi-line string
        keeps indentation
      and ''${escaped} interpolation, ${plain}
      ''
let nothing = None Natural
let something = Some 5
let timeOfDay = 08:30:00
let dateValue = 2026-03-01
let zone = +01:00
let timestamp = 2026-03-01T08:30:00+01:00
let url = https://example.com/stock.dhall
let urlWithHeaders = https://example.com/stock.dhall using ./headers.dhall
let localPath = ./config/defaults.dhall
let parentPath = ../shared/types.dhall
let homePath = ~/dhall/prelude.dhall
let absPath = /etc/warehouse/config.dhall
let envVar = env:WAREHOUSE_HOME as Text
let missingValue = missing
let hashed = ./types.dhall sha256:0000000000000000000000000000000000000000000000000000000000000000
let asLocation = ./types.dhall as Location
let asText = ./README.txt as Text
let asBytes = ./blob.bin as Bytes
let fallback = env:MAYBE_UNSET ? ./local-default.dhall ? missing

-- ── Types ──
let Environment = < Dev | Staging | Prod >

let Category = < Tools | Fasteners | Safety : { level : Natural } | Bulk : Natural >

let Item =
      { sku : Text
      , qty : Natural
      , price : Double
      , category : Category
      , notes : Optional Text
      }

let Service =
      { Type =
          { name : Text
          , replicas : Natural
          , env : Environment
          , ports : List Natural
          }
      , default = { replicas = 2, env = Environment.Dev, ports = [ 8080 ] }
      }

let Pair = \(a : Type) -> \(b : Type) -> { _1 : a, _2 : b }

-- ── Functions ──
let mkService =
      \(name : Text) ->
      \(env : Environment) ->
        Service::{
        , name
        , env
        , replicas = merge { Dev = 1, Staging = 2, Prod = 6 } env
        }

let double = λ(n : Natural) → n * 2

let identity = \(a : Type) -> \(x : a) -> x

let compose =
      \(a : Type) ->
      \(b : Type) ->
      \(c : Type) ->
      \(f : a -> b) ->
      \(g : b -> c) ->
      \(x : a) ->
        g (f x)

let describe =
      \(c : Category) ->
        merge
          { Tools = "tools"
          , Fasteners = "fasteners"
          , Safety = \(s : { level : Natural }) -> "safety ${Natural/show s.level}"
          , Bulk = \(w : Natural) -> "bulk ${Natural/show w}"
          }
          c

-- ── Operators and builtins ──
let ops =
      { arithmetic = (1 + 2) * 3
      , logic = True && False || True == False != True
      , text = "a" ++ "b"
      , list = [ 1, 2 ] # [ 3 ]
      , recordMerge = { a = 1 } ∧ { b = 2 }
      , recordMergeAscii = { a = 1 } /\ { b = 2 }
      , override = { a = 1, b = 2 } // { b = 3 }
      , overrideUnicode = { a = 1 } ⫽ { c = 3 }
      , combineTypes = { a : Natural } ⩓ { b : Text }
      , combineTypesAscii = { a : Natural } //\\ { b : Text }
      , projection = { a = 1, b = 2, c = 3 }.{ a, b }
      , projectionByType = { a = 1, b = "x" }.({ a : Natural })
      , access = { a = 1 }.a
      , assertion = assert : 1 + 1 === 2
      , equivalence = 2 ≡ 2
      , toMap = toMap { a = "x", b = "y" }
      , showVariants = [ Natural/show 5, Integer/show +5, Double/show 1.5 ]
      , conversions = [ Natural/toInteger 5, Integer/toDouble +5, Integer/clamp -3, Integer/negate +4 ]
      , predicates = [ Natural/isZero 0, Natural/even 4, Natural/odd 3 ]
      , lists = [ List/length Natural [ 1, 2 ], List/head Natural [ 1 ], List/last Natural [ 1 ] ]
      , reverse = List/reverse Natural [ 1, 2, 3 ]
      , fold = Natural/fold 3 Natural (\(x : Natural) -> x + 2) 0
      , listBuild = List/build Natural (\(list : Type) -> \(cons : Natural -> list -> list) -> \(nil : list) -> cons 1 nil)
      , listFold = List/fold Natural [ 1, 2, 3 ] Natural (\(x : Natural) -> \(acc : Natural) -> x + acc) 0
      , optionalFold = Optional/fold Natural (Some 1) Natural (\(x : Natural) -> x) 0
      , textShow = Text/show "quoted"
      , textReplace = Text/replace "a" "b" "banana"
      , textDefault = None Text
      , empty = [] : List Natural
      , emptyMap = toMap {=} : List { mapKey : Text, mapValue : Text }
      , emptyRecord = {=}
      , emptyRecordType = {}
      , typeOfType = Type
      , typeKind = Kind
      , typeSort = Sort
      , forall = forall (a : Type) -> a -> a
      , forallUnicode = ∀(a : Type) → a → a
      }

-- ── Conditionals, let-bindings, annotations ──
let pick =
      \(flag : Bool) ->
        if flag then "yes" else "no"

let annotated : Natural = 5

let withAnnotation = (5 : Natural)

let nestedLets =
      let x = 1
      let y = 2
      let z : Natural = x + y
      in  z

let services =
      [ mkService "api" Environment.Prod
      , mkService "worker" Environment.Staging // { ports = [] : List Natural }
      ]

let items : List Item =
      [ { sku = "A-100", qty = 12, price = 4.5, category = Category.Tools, notes = Some "fragile" }
      , { sku = "B-200"
        , qty = 0
        , price = 19.99
        , category = Category.Safety { level = 3 }
        , notes = None Text
        }
      ]

let with_ = { a = { b = { c = 1 } } } with a.b.c = 2

let uniqueNames = Natural/fold 0 Natural (\(x : Natural) -> x) 0


-- ── Further constructs ──
let Text/concatSep = https://prelude.dhall-lang.org/Text/concatSep
let List/map = https://prelude.dhall-lang.org/List/map sha256:dd845ffb4568d40327f2a817eb42d1c6138b929ca758d50bc33112ef3c885680
let Natural/sum = https://prelude.dhall-lang.org/Natural/sum

let Optional/default = \(a : Type) -> \(d : a) -> \(o : Optional a) -> merge { Some = \(x : a) -> x, None = d } o

let unions = [ < A | B : Natural >.A, < A | B : Natural >.B 1 ]

let records =
      { nested = { deeper = { deepest = "x" } }
      , quoted = { `field with spaces` = 1, `if` = 2 }
      , typeLevel = { a : Natural, b : Optional Text }
      , dotted = { a.b.c = 1 }
      }

let projections = records.nested.deeper.{ deepest }

let numericEdge =
      { negZero = -0.0
      , posInt = +0
      , hexFloat = 0x10
      , bigNat = 18446744073709551615
      , tiny = 1e-300
      , huge = 1.7976931348623157e308
      }

let textEdge =
      { empty = ""
      , dollar = "\$"
      , braces = "\${not interpolation}"
      , unicodeEsc = "\u0041\u{1F600}"
      , interpolatedNesting = "a ${"b ${"c"}"} d"
      , multiEmpty = ''
''
      , multiTab = ''
	indented with tab
''
      }

let importsAsLocation = ./types.dhall as Location
let importsHeaders = https://example.com/x.dhall using (toMap { Authorization = "Bearer example-not-a-real-token" })
let envImport = env:HOME
let envQuoted = env:"WEIRD-NAME"

let isoTimes = { d = 2026-03-01, t = 08:30:00.123, z = Z, tz = 2026-03-01T08:30:00-05:00 }

let assertions =
      [ assert : Natural/fold 2 Natural (\(n : Natural) -> n + 1) 0 === 2
      , assert : (\(x : Natural) -> x + 0) === (\(y : Natural) -> y)
      ]

let toMapTyped = toMap { x = 1 } : List { mapKey : Text, mapValue : Natural }
let someNone = [ Some 1, None Natural ]
let typedEmpty = [] : List { a : Natural }
let lambdaUnicode = λ(x : Type) → λ(y : x) → y
let arrowUnicode = ∀(x : Type) → x → x
let combine = { a = 1 } ∧ { b = 2 } ⫽ { c = 3 }
let showExample = Natural/show 5 ++ Integer/show -3 ++ Double/show 1.5 ++ Text/show "q"

-- ── Recent builtins (standard 23.x) ──
let recent =
      { subtract = Natural/subtract 2 5
      , constructor = showConstructor (< A | B : Natural >.B 1)
      , timeType = [ Date, Time, TimeZone ]
      , dateShow = Date/show 2026-03-01
      , timeShow = Time/show 08:30:00
      , zoneShow = TimeZone/show +01:00
      , textAppend = Text/replace "\${" "" "x"
      , indexed = List/indexed Natural [ 10, 20 ]
      , optionalBuild = Optional/build Natural (\(optional : Type) -> \(some : Natural -> optional) -> \(none : optional) -> some 1)
      }

in  { services
    , items
    , region = "eu-west-1"
    , debug = False
    , version = 1
    , tags = [ "a", "b" ]
    , ops
    , pick
    , with_
    }
