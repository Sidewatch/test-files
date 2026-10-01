// F# 10 (.NET 10) — syntax showcase
// ── Comments ──
// F#: an inventory domain model with every syntactic category.
(* Block comment (* nested block comment *) still inside *)
/// XML doc comment for the module.
/// <summary>Warehouse inventory showcase.</summary>
/// <remarks>TODO: split into several files. FIXME: rounding.</remarks>
module Acme.Warehouse.Sample

#nowarn "25" "49"
#if DEBUG
#define VERBOSE
#else
#endif
#light "on"

// ── Opens and abbreviations ──
open System
open System.Collections.Generic
open System.Text.RegularExpressions
open type System.Math
module M = Microsoft.FSharp.Collections.Map
type StringMap<'v> = Dictionary<string, 'v>

// ── Literals ──
let integer = 42
let negative = -7
let hex = 0xFF
let octal = 0o755
let binary = 0b1010_1010
let big = 1_000_000
let bigint = 123456789012345678901234567890I
let byteVal = 255uy
let sbyteVal = -1y
let int16Val = 12s
let uint16Val = 12us
let int32Val = 12l
let uint32Val = 12u
let int64Val = 12L
let uint64Val = 12UL
let nativeVal = 12n
let unativeVal = 12un
let single = 3.14f
let double = 6.02e23
let decimalVal = 120.50m
let unitVal = ()
let boolTrue, boolFalse = true, false
let nan' = nan
let inf = infinity

// ── Characters and strings ──
let ch = 'a'
let escapedChar = '\n'
let unicodeChar = '\u0041'
let trigraph = '\065'
let plain = "tab\there \"quoted\" \\ back \u00e9 \U0001F600 \x41"
let verbatim = @"C:\warehouse\bin ""quoted"""
let triple = """Triple "quoted" with \ no escapes
and a second line"""
let bytes = "bytes"B
let charByte = 'a'B
let interpolated = $"Order {integer} costs {decimalVal:F2} and {(if boolTrue then "yes" else "no")}"
let interpVerbatim = $@"Path {plain}\x"
let tripleInterp = $"""Value {integer} and {{braces}}"""
let multiDollar = $$"""JSON-like {{ "k": {{integer}} }}"""
let continued = "line one \
                 line two"
let formatted = sprintf "%d %s %5.2f %A %O %x %c %b %M" 1 "s" 2.5 [1] None 255 'c' true 1m
let regex = Regex(@"^[A-Z]{3}-\d{4}$")

// ── Operators ──
let arith = 1 + 2 - 3 * 4 / 5 % 6
let power = 2.0 ** 10.0
let bitwise = (0xF0 &&& 0x3C) ||| (0x01 <<< 4) ^^^ (0xFF >>> 2) |> (~~~)
let logic = true && not false || false
let compare = 1 < 2 && 2 <= 3 && 3 > 2 && 3 >= 3 && 1 <> 2 && 1 = 1
let physical = obj.ReferenceEquals(ch, ch)
let mutable counter = 0
counter <- counter + 1
let range = [ 1 .. 10 ]
let stepped = [ 0 .. 5 .. 100 ]
let chars = [ 'a' .. 'e' ]
let slice = range.[2..4]
let slice2 = range[..3]
let opt = Some 1 |> Option.map ((+) 1) |> Option.defaultValue 0
let compose = (fun x -> x + 1) >> (fun x -> x * 2) << (fun x -> x - 1)
let pipes = [ 1; 2; 3 ] |> List.map (fun x -> x * x) ||> (fun a b -> a)
let (|>>) a f = f a
let (+++) (a: string) (b: string) = a + " " + b
let inline (<+>) a b = a + b

// ── Type definitions: records, unions, enums, abbreviations ──
[<Measure>] type kg
[<Measure>] type m
let weight = 12.5<kg>
let area = 3.0<m^2>

type Status =
    | Pending
    | Paid of paidOn: DateTime
    | Shipped of carrier: string * tracking: string
    | Cancelled of reason: string

type Color =
    | Red = 0
    | Green = 1
    | Blue = 2

[<Struct>]
type Point = { X: float; Y: float }

[<CLIMutable>]
type Sku =
    { Code: string
      Quantity: int
      Price: decimal
      mutable Notes: string option }
    member this.Total = decimal this.Quantity * this.Price
    static member Empty = { Code = ""; Quantity = 0; Price = 0m; Notes = None }

type Order = { Number: int; Total: decimal; Status: Status; Lines: Sku list }

[<RequireQualifiedAccess>]
type Priority = Low | Normal | High

[<Struct; CustomEquality; NoComparison>]
type Id =
    | Id of int
    override this.Equals(o) = match o with :? Id as other -> this = other | _ -> false
    override this.GetHashCode() = 0

// ── Active patterns ──
let (|Even|Odd|) n = if n % 2 = 0 then Even else Odd
let (|Integer|_|) (s: string) =
    match Int32.TryParse s with
    | true, v -> Some v
    | _ -> None
let (|ParseRegex|_|) pattern input =
    let m = Regex.Match(input, pattern)
    if m.Success then Some [ for g in m.Groups -> g.Value ] else None

// ── Functions ──
let add x y = x + y
let rec factorial n = if n <= 1 then 1 else n * factorial (n - 1)
let rec isEven n = n = 0 || isOdd (n - 1)
and isOdd n = n <> 0 && isEven (n - 1)
let inline square x = x * x
let curried (a: int) (b: int) : int = a + b
let tupled (a: int, b: int) = a + b
let generic<'T when 'T : comparison> (a: 'T) (b: 'T) = if a < b then a else b
let withOptional ([<Optional; DefaultParameterValue(1)>] n: int) = n
let lambda = fun (x: int) -> x + 1
let function' = function
    | 0 -> "zero"
    | n when n < 0 -> "negative"
    | _ -> "positive"
let useParam (_: unit) = ()

// ── Pattern matching ──
let describe order =
    match order.Status with
    | Pending -> sprintf "#%d pending" order.Number
    | Paid on -> sprintf "#%d paid on %s" order.Number (on.ToString "yyyy-MM-dd")
    | Shipped (carrier, tracking) when tracking <> "" -> sprintf "#%d via %s %s" order.Number carrier tracking
    | Shipped _ -> "shipped"
    | Cancelled reason when reason.Length > 0 -> sprintf "#%d cancelled: %s" order.Number reason
    | Cancelled _ -> sprintf "#%d cancelled" order.Number

let classify = function
    | Even -> "even"
    | Odd -> "odd"

let patterns (x: obj) =
    match x with
    | :? int as i when i > 0 -> "positive int"
    | :? string as s -> "string " + s
    | null -> "null"
    | [] -> "empty list"
    | [ a ] -> "one"
    | a :: b :: rest -> "many"
    | (1 | 2 | 3) -> "small"
    | Integer n -> "parsed"
    | _ -> "other"

let tuplePat, (a, b) = (1, 2), (3, 4)
let { X = px; Y = py } = { X = 1.0; Y = 2.0 }

// ── Control flow ──
let control n =
    if n > 0 then "pos"
    elif n < 0 then "neg"
    else "zero"

let loops () =
    for i in 1 .. 10 do
        if i % 2 = 0 then printfn "%d" i
    for i = 10 downto 1 do ()
    for (k, v) in Map.toList (Map.ofList [ 1, "a" ]) do ()
    let mutable i = 0
    while i < 3 do
        i <- i + 1
    for KeyValue(k, v) in dict [ 1, 2 ] do ()

let exceptions () =
    try
        try
            failwith "boom"
        with
        | :? ArgumentException as ex -> printfn "%s" ex.Message
        | Failure msg -> printfn "failure %s" msg
        | _ -> reraise ()
    finally
        printfn "cleanup"

exception InsufficientStock of sku: string * wanted: int
let raiser () = raise (InsufficientStock("A-1", 5))
let invalid () = invalidArg "x" "bad" |> ignore; invalidOp "no" |> ignore; nullArg "n"

// ── Collections and comprehensions ──
let orders =
    [ { Number = 1; Total = 120.50m; Status = Paid (DateTime(2026, 9, 24)); Lines = [] }
      { Number = 2; Total = 0m; Status = Cancelled "duplicate"; Lines = [] }
      { Number = 3; Total = 42m; Status = Pending; Lines = [] } ]

let arrayLit = [| 1; 2; 3 |]
let seqExp = seq { for i in 1 .. 3 do yield i * i }
let listComp = [ for o in orders do if o.Total > 0m then yield o.Number ]
let arrayComp = [| for i in 1 .. 3 -> i |]
let withYieldBang = [ yield! [ 1; 2 ]; yield 3 ]
let mapLit = Map.ofList [ "a", 1; "b", 2 ]
let setLit = Set.ofSeq [ 1; 2; 2 ]
let cons = 0 :: [ 1; 2 ]
let append = [ 1 ] @ [ 2 ]
let copyUpdate = { Sku.Empty with Code = "Z-9"; Quantity = 3 }

let revenue =
    orders
    |> List.filter (fun o -> match o.Status with Paid _ -> true | _ -> false)
    |> List.sumBy (fun o -> o.Total)

// ── Classes, interfaces, inheritance ──
type IShape =
    abstract Area : float
    abstract Describe : unit -> string

[<AbstractClass>]
type Shape(name: string) =
    member _.Name = name
    abstract Area : float
    default _.ToString() = name

type Circle(radius: float) =
    inherit Shape("circle")
    let mutable scale = 1.0
    do printfn "created circle"
    new() = Circle(1.0)
    member val Label = "c" with get, set
    member this.Scale with get () = scale and set (v: float) = scale <- v
    override _.Area = PI * radius * radius
    interface IShape with
        member this.Area = this.Area
        member this.Describe() = $"circle {radius}"
    interface IDisposable with
        member _.Dispose() = ()
    static member Unit = Circle(1.0)
    static member (+) (a: Circle, b: Circle) = Circle(1.0)

let objectExpr =
    { new IShape with
        member _.Area = 1.0
        member _.Describe() = "unit" }

type Stack<'T>() =
    let items = Stack<'T>()
    member _.Push(x: 'T) = items.Push x
    member _.Item with get (i: int) = Seq.item i items

type Extensions =
    [<System.Runtime.CompilerServices.Extension>]
    static member Double(x: int) = x * 2

type System.String with
    member s.Shout() = s.ToUpper() + "!"

// ── Computation expressions and async ──
let fetch (url: string) = async {
    do! Async.Sleep 10
    let! result = async { return url.Length }
    use d = { new IDisposable with member _.Dispose() = () }
    return! async { return result + 1 }
}

let maybe = option {
    let! a = Some 1
    and! b = Some 2
    return a + b
}

let task' = task {
    let! x = System.Threading.Tasks.Task.FromResult 1
    return x
}

type OptionBuilder() =
    member _.Bind(m, f) = Option.bind f m
    member _.Return x = Some x
    member _.Zero() = None
let option = OptionBuilder()

let query' = query {
    for o in orders do
    where (o.Total > 10m)
    select o.Number
}

// ── Quotations, lazy, byref, inline IL, attributes ──
let quoted = <@ 1 + 2 @>
let untyped = <@@ 1 + 2 @@>
let spliced = <@ %quoted + 1 @>
let lazyVal = lazy (1 + 1)
let forced = lazyVal.Force()
let addressOf (x: byref<int>) = x <- x + 1
let boxed = box 1 :?> int
let upcast' = (3 :> obj)
let typeOf = typeof<int>
let nameOf = nameof orders
let defaultOf = Unchecked.defaultof<int>
let sizeOf = sizeof<int>
let assertion = assert (1 = 1)
let useDisposable = use res = new System.IO.StringReader("x") in res.ReadToEnd()

// ── Script directives (inside INTERACTIVE only) ──
#if INTERACTIVE
#r "nuget: Newtonsoft.Json, 13.0.3"
#r "System.Xml.dll"
#I "/usr/local/lib"
#load "Helpers.fsx"
#time "on"
#help
#quit
#endif
#line 1 "generated.fs"
#line hidden

// ── Special identifiers and literals ──
let sourceDir = __SOURCE_DIRECTORY__
let sourceFile = __SOURCE_FILE__
let sourceLine = __LINE__
let ``double backtick identifier`` = 1
let ``another name with spaces`` x = x + ``double backtick identifier``
[<Literal>]
let LiteralValue = 42
[<Literal>]
let LiteralText = "constant"
let matchLiteral x =
    match x with
    | LiteralValue -> "forty-two"
    | _ -> "other"
let unsignedHex = 0xFFFFFFFFu
let lowerHex = 0xdeadbeefL
let floatSci = 1E3
let floatSuffix = 1.0F
let floatNeg = -1.5e-3
let decimalSci = 1.5e3M
let tupleBig = (1I, 2UL, 3uy)
let verbatimQuotes = @"a ""b"" c"
let tripleQuotes = """a "b" c"""
let escapes = "\a \b \f \n \r \t \v \\ \" \' \0 \065 \x41 \u0041 \U00000041"
let charEscapes = ['\a'; '\b'; '\f'; '\n'; '\r'; '\t'; '\v'; '\\'; '\"'; '\''; '\0']

// ── Remaining keywords in context ──
module Keywords =
    let useBang () = async {
        use! res = async { return { new IDisposable with member _.Dispose() = () } }
        let! r = async { return 1 }
        do! Async.Sleep 1
        match! async { return 1 } with
        | 1 -> return ()
        | _ -> return! async { return () }
    }

    let bitwiseKeywords = (1 <<< 2) ||| (3 &&& 1) ^^^ 2 |> ignore
    let shiftWords = (1 <<< 2, 8 >>> 1)
    let oldBitwise = (4 ||| 1, 4 &&& 1, 4 ^^^ 1, ~~~4)
    let beginEnd =
        begin
            if true then 1 else 2
        end
    let forDone =
        for i in 1 .. 2 do
            ()
    let asPattern = match (1, 2) with | (a, _) as whole -> whole
    let downcasted = (box "s") :?> string
    let upcasted : obj = upcast "s"
    let downcasted2 : string = downcast (box "s")
    let nullable : string = null
    let voidReturn : unit = ()
    let internalValue = 1
    let inlineIf = if true then "a" else "b"
    let tailCall () = ()
    let yieldReturn = seq { yield 1; yield! [ 2; 3 ] }
    let toDownTo = [ for i in 10 .. -1 .. 1 -> i ]

module rec RecursiveModule =
    type A = { B: B }
    and B = { A: A option }
    let f x = g x
    and g x = x

type internal InternalType = { Hidden: int }
type private PrivateType() = class end
type public PublicType() = class end

type ExplicitClass =
    class
        val mutable field : int
        val readonly : string
        new (f, r) = { field = f; readonly = r }
        member x.Field = x.field
    end

type StructType =
    struct
        val X : int
        val Y : int
        new (x, y) = { X = x; Y = y }
    end

type MyInterface =
    interface
        abstract Name : string
        abstract Run : int * string -> unit
    end

type Delegate1 = delegate of int * int -> int
type Delegate2 = delegate of unit -> unit
let useDelegate = Delegate1(fun a b -> a + b)
let invoked = useDelegate.Invoke(1, 2)

type WithEvents() =
    let changed = Event<EventHandler, EventArgs>()
    let evt = new Event<int>()
    [<CLIEvent>]
    member _.Changed = changed.Publish
    member _.Evt = evt.Publish
    member _.Raise() = evt.Trigger 1

type WithStatic() =
    static let mutable count = 0
    static member Count with get () = count and set v = count <- v
    static member val Default = WithStatic() with get, set
    [<DefaultValue>] val mutable Late : int
    member val Auto = 1 with get, set
    abstract member Virtual : int -> int
    default _.Virtual x = x
    member private _.Hidden = 1
    member internal _.Internal = 2

type Inherited() =
    inherit WithStatic()
    override _.Virtual x = x + 1
    member _.CallBase() = base.Virtual 1

type Gen<'a, 'b when 'a : equality and 'b : not struct and 'a :> IComparable> = { A: 'a; B: 'b }
type Gen2<'T when 'T : (new : unit -> 'T) and 'T : struct and 'T : null and 'T : unmanaged and 'T : enum<int> and 'T : delegate<int, unit>> = class end
let inline addMembers< ^T when ^T : (static member (+) : ^T * ^T -> ^T)> (a: ^T) (b: ^T) = a + b
let statically<'T> () = typeof<'T>.Name
let flexible (xs: #seq<int>) = Seq.sum xs
let anonymousRecord = {| Name = "widget"; Qty = 3 |}
let structAnon = struct {| X = 1; Y = 2 |}
let structTuple = struct (1, 2)
let (struct (sa, sb)) = structTuple
let byrefExample (x: byref<int>) (y: inref<int>) (z: outref<int>) = ()
let spanExample (s: System.Span<byte>) = s.Length
let measureGeneric<[<Measure>] 'u> (x: float<'u>) = x
let resultExample : Result<int, string> = Ok 1
let optionPatterns = function Some x when x > 0 -> x | Some _ | None -> 0
let valueOption : int voption = ValueSome 1
let (|>!) x f = f x; x
let lazyList = lazy (seq { 1 .. 3 })

// ── Operators table ──
let allOperators =
    let a, b = 1, 2
    [ a + b; a - b; a * b; a / b; a % b ]
    |> List.append [ a <<< 1; a >>> 1; a &&& b; a ||| b; a ^^^ b; ~~~a ]
    |> List.map (fun x -> -x)
let boolOps = (true && false) || not true
let cmpOps = (1 < 2, 1 > 2, 1 <= 2, 1 >= 2, 1 = 2, 1 <> 2, compare 1 2)
let assignOps =
    let mutable x = 0
    x <- 1
    x <- x + 1
    let r = ref 0
    r := 1
    r.Value <- !r + 1
    x
let rangeOps = [ 1 .. 3 ], [ 1 .. 2 .. 9 ], [ 'a' .. 'c' ], seq { 0 .. 2 }
let sliceOps = "hello".[1..3], [| 1; 2; 3 |].[..1], [| 1; 2; 3 |].[1..], [ 1; 2; 3 ].[1]
let optionOps = Some 1 |> Option.map ((+) 1), (Some 1 <|> None) |> ignore
let (<|>) a b = match a with Some _ -> a | None -> b
let applyOps = (+) 1 <| 2, 2 |> (+) 1, ((+) 1 >> (*) 2) 3, ((*) 2 << (+) 1) 3
let tuplePipes = (1, 2) ||> (+), (1, 2, 3) |||> (fun a b c -> a + b + c)
let typeTest = (box 1) :? int, (box "s") :? string
let nullCoalesce = match null with null -> 0 | _ -> 1

// ── Format specifiers ──
let formats = sprintf "%b %c %s %d %i %u %x %X %o %e %E %f %F %g %G %M %O %A %P %% %*d %-5d %+d %05d %.3f %10s %-10s" true 'c' "s" 1 2 3u 255 255 8 1.0 1.0 2.0 2.0 3.0 3.0 1m (obj()) [1] 0 5 1 1 1 1.0 "a" "b"
let interpFormats = $"{1:N2} {2.5:F1} {DateTime.Now:yyyy-MM-dd} {42,5} {42,-5} {{literal}} {true} %d{3} %s{"x"}"

// ── F# 8–10 additions: nullness, _.Member shorthand, static abstract, TailCall, and! ──
#nullable enable
let nullableString : string | null = null
let lengthOrZero (s: string | null) =
    match s with
    | null -> 0
    | s -> s.Length
let withNullCheck (s: string | null) = nonNull s
let dotShorthand = orders |> List.map _.Number
let dotShorthandChain = orders |> List.map _.Status.ToString()
let dotShorthandFilter = orders |> List.filter (_.Total >> (>) 10m)

type IAddable<'T when 'T :> IAddable<'T>> =
    static abstract member Zero : 'T
    static abstract member (+) : 'T * 'T -> 'T

type Meters(v: float) =
    member _.Value = v
    interface IAddable<Meters> with
        static member Zero = Meters(0.0)
        static member (+) (a, b) = Meters(a.Value + b.Value)

let sumAll<'T when 'T :> IAddable<'T>> (xs: 'T list) = List.fold (+) 'T.Zero xs

[<TailCall>]
let rec countdown n acc = if n = 0 then acc else countdown (n - 1) (acc + n)

let parallelBinds = task {
    let! a = System.Threading.Tasks.Task.FromResult 1
    and! b = System.Threading.Tasks.Task.FromResult 2
    return a + b
}

// ── Extra declarations: extern, fixed, const, namespaces, ML-compat operators (deprecated) ──
open System.Runtime.InteropServices
[<DllImport("libc", EntryPoint = "getpid")>]
extern int getpid()

type Provided = SomeProvider<const "config.json", Size = 10>
let fixedExample (arr: byte[]) =
    use ptr = fixed &arr.[0]
    NativeInterop.NativePtr.read ptr
let mlOperators = (7 % 3, 1 <<< 2, 8 >>> 1) // deprecated ML forms: mod, land, lor, lxor, lsl, lsr, asr
let legacyRefCells =
    let r = ref 0
    r := !r + 1 // deprecated: use r.Value
    r.Value
type Pair = { Left: int; Right: int } with
    member this.Sum = this.Left + this.Right
    static member Zero = { Left = 0; Right = 0 }
type Choice' = | A | B with
    override this.ToString() = match this with A -> "a" | B -> "b"
exception ValidationFailed of string with
    override this.Message = "validation failed"
type Lazy' = Lazy<int>
let forwardPipeTypes : int list -> int = List.sum
let functionType : (int -> int) -> int list -> int list = List.map
let tupleType : int * string * bool = 1, "a", true
let arrayType : int[] * int[,] * int[,,] = [| 1 |], Array2D.zeroCreate 1 1, Array3D.zeroCreate 1 1 1
let genericInstance = System.Collections.Generic.List<int>()
let hashDirectiveEnd =
#if DEBUG
    "debug"
#elif RELEASE
    "release"
#else
    "other"
#endif

[<EntryPoint>]
let main argv =
    orders |> List.iter (describe >> printfn "%s")
    printfn "revenue: %M" revenue
    0
