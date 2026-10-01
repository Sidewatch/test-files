(* Standard ML '97 (Revised Definition) with the Basis Library — syntax showcase *)
(* ── Comments ── *)
(* Standard ML: a warehouse stock model.
   (* Comments nest, so this inner one is still inside. *)
   TODO: persist the ledger.
   FIXME: rounding in the average. *)

(* ── Literals ── *)
val int_dec = 42
val int_neg = ~7
val int_hex = 0xFF
val word_dec = 0w42
val word_hex = 0wxFF
val real_plain = 3.14
val real_neg = ~0.5
val real_exp = 1.5e10
val real_negexp = 2.5E~3
val str_plain = "plain string"
val str_escapes = "tab\there\nnewline \"quoted\" back\\slash \065 A \^A"
val str_gap = "a long string \
              \continued across lines"
val str_more_escapes = "alarm\a backspace\b formfeed\f return\r vtab\v nul\000 ctrl\^Z unicode\u00E9"
val str_empty = ""
val chr_a = #"a"
val chr_nl = #"\n"
val unit_value = ()
val bool_t = true
val bool_f = false
val nil_list = []
val tuple = (1, "two", 3.0, #"4")
val record = { sku = "ABC-1", quantity = 12, price = 2.5 }
val tuple_sel = #2 tuple
val record_sel = #quantity record

(* ── Datatypes ── *)
datatype status = Pending | Paid of real | Shipped of string * int | Cancelled of string

datatype 'a tree = Leaf | Node of 'a tree * 'a * 'a tree

datatype ('k, 'v) entry = Entry of { key : 'k, value : 'v }

datatype expr =
    Num of int
  | Add of expr * expr
  | Mul of expr * expr
  | Neg of expr

(* ── Type abbreviations ── *)
type sku = string
type item = { sku : sku, name : string, quantity : int, status : status }
type 'a pair = 'a * 'a
type ('a, 'b) assoc = ('a * 'b) list

(* ── Exceptions ── *)
exception OutOfStock of sku
exception InvalidQuantity
exception Fatal of string * int

(* ── Functions ── *)
fun double x = 2 * x
fun add (a, b) = a + b
fun curried a b c = a + b * c

fun fact 0 = 1
  | fact n = n * fact (n - 1)

fun fib n =
  let
    fun go (0, a, _) = a
      | go (k, a, b) = go (k - 1, b, a + b)
  in
    go (n, 0, 1)
  end

fun describe ({ sku, status, ... } : item) =
  case status of
      Pending => sku ^ " pending"
    | Paid amount => sku ^ " paid (" ^ Real.toString amount ^ ")"
    | Shipped (carrier, days) => sku ^ " shipped via " ^ carrier ^ " in " ^ Int.toString days ^ "d"
    | Cancelled "" => sku ^ " cancelled"
    | Cancelled reason => sku ^ " cancelled: " ^ reason

fun len [] = 0
  | len (_ :: rest) = 1 + len rest

fun map' f [] = []
  | map' f (x :: xs) = f x :: map' f xs

and filter' p [] = []
  | filter' p (x :: xs) = if p x then x :: filter' p xs else filter' p xs

fun insert (Leaf, x) = Node (Leaf, x, Leaf)
  | insert (t as Node (l, v, r), x) =
      if x < v then Node (insert (l, x), v, r)
      else if x > v then Node (l, v, insert (r, x))
      else t

fun eval (Num n) = n
  | eval (Add (a, b)) = eval a + eval b
  | eval (Mul (a, b)) = eval a * eval b
  | eval (Neg e) = ~ (eval e)

fun remove ({ sku, quantity, ... } : item, n) =
  if n <= 0 then raise InvalidQuantity
  else if n > quantity then raise OutOfStock sku
  else quantity - n

(* ── Anonymous functions, val rec, operators ── *)
val square = fn x => x * x
val rec loop = fn 0 => 0 | n => loop (n - 1)
val composed = (fn x => x + 1) o (fn x => x * 2)
val applied = square 5 before print "side effect\n"
infix 6 +++
fun a +++ b = a + b + 1
infixr 5 :::
fun x ::: xs = x :: xs
nonfix +++
op +++ (1, 2)

(* ── Let, local, patterns ── *)
val total =
  let
    val a = 1
    val b = a + 1
    val (c, d) = (b * 2, b * 3)
    val { sku = s, quantity = q, ... } = record
    val x :: _ = [1, 2, 3]
    val _ = print "ignored\n"
  in
    a + b + c + d + q
  end

local
  val hidden = 10
  fun helper x = x + hidden
in
  fun exposed x = helper x * 2
end

(* ── Conditionals, case, handle, raise ── *)
val label = if total > 10 andalso total < 100 orelse false then "mid" else "other"

val safe_remove =
  remove ({ sku = "ABC-1", name = "Hammer", quantity = 5, status = Pending }, 10)
  handle OutOfStock s => (print ("out of " ^ s ^ "\n"); 0)
       | InvalidQuantity => ~1
       | Fatal (msg, code) => code
       | _ => raise Fail "unexpected"

val sign = fn n => case Int.compare (n, 0) of LESS => ~1 | EQUAL => 0 | GREATER => 1

(* ── While loops and refs ── *)
val counter = ref 0
val () = while !counter < 5 do counter := !counter + 1
val _ = (counter := !counter + 1; !counter)

(* ── Lists and the basis library ── *)
val numbers = [1, 2, 3, 4, 5]
val evens = List.filter (fn n => n mod 2 = 0) numbers
val sum = List.foldl op+ 0 numbers
val product = List.foldr (fn (n, acc) => n * acc) 1 numbers
val halves = List.map (fn n => real n / 2.0) numbers
val strs = map Int.toString numbers
val joined = String.concatWith ", " strs
val upper = String.map Char.toUpper "hello"
val sliced = Substring.string (Substring.extract ("warehouse", 0, SOME 4))
val zipped = ListPair.zip (numbers, strs)
val divmod = (17 div 5, 17 mod 5, 17 - 5 * 3, 7.0 / 2.0)
val comparison = (1 < 2, 2 <= 2, 3 > 4, 4 >= 4, 5 <> 6, "a" = "a")
val appended = [1, 2] @ [3] @ (0 :: [])
val concatenated = "a" ^ "b" ^ implode [#"c", #"d"]

(* ── Modules: signatures ── *)
signature STOCK =
sig
  type t
  exception Empty
  val empty : t
  val add : sku * int * t -> t
  val remove : sku * int * t -> t
  val count : sku * t -> int
  val toList : t -> (sku * int) list
  eqtype id
  datatype kind = Raw | Finished
  structure Inner : sig val x : int end
end

(* ── Modules: structures ── *)
structure Stock :> STOCK =
struct
  type t = (sku * int) list
  exception Empty
  type id = int
  datatype kind = Raw | Finished
  structure Inner = struct val x = 1 end
  val empty = []

  fun count (_, []) = 0
    | count (s, (k, n) :: rest) = if s = k then n else count (s, rest)

  fun add (s, n, []) = [(s, n)]
    | add (s, n, (k, m) :: rest) =
        if s = k then (k, m + n) :: rest else (k, m) :: add (s, n, rest)

  fun remove (s, n, ledger) =
    let val have = count (s, ledger)
    in if n > have then raise OutOfStock s else add (s, ~n, ledger) end

  fun toList ledger = ledger
end

(* ── Modules: functors ── *)
signature ORDERED =
sig
  type t
  val compare : t * t -> order
end

functor MakeSet (Elt : ORDERED) =
struct
  type elt = Elt.t
  type set = elt list
  val empty : set = []
  fun member (_, []) = false
    | member (x, y :: ys) =
        case Elt.compare (x, y) of
            EQUAL => true
          | LESS => false
          | GREATER => member (x, ys)
end

structure IntOrd = struct type t = int val compare = Int.compare end
structure IntSet = MakeSet (IntOrd)
structure Local = struct open Stock val extra = 1 end

functor Counter (val start : int) : sig val next : unit -> int end =
struct
  val r = ref start
  fun next () = (r := !r + 1; !r)
end

(* ── where, sharing, include, abstype, open ── *)
signature SHARED = sig structure A : ORDERED structure B : ORDERED sharing type A.t = B.t end
signature REFINED = ORDERED where type t = int
abstype counter_t = C of int with
  fun make () = C 0
  fun bump (C n) = C (n + 1)
  fun read (C n) = n
end
open List
val _ = hd [1]

(* ── More literals and patterns ── *)
val real_exp_pos = 6.02E23
val real_small = 1e~9
val int_negative_hex = ~0xFF
val word_binary_ops = (0w5 + 0w3, 0wxF)
val list_literal = [1, 2, 3]
val nested_tuple = ((1, 2), (3, [4, 5]))
val flexible = (fn ({ sku, ... } : item) => sku)
val first_two = (fn [a, b] => a + b | _ => 0)
val typed_value = (42 : int)
val typed_fun = (fn (x : int) => x + 1)
val as_pattern = (fn (all as x :: _) => (x, all) | [] => (0, []))
val eq_tyvar : ''a list -> ''a -> bool = fn l => fn x => List.exists (fn y => y = x) l

(* ── Explicit type variables ── *)
fun 'a identity (x : 'a) : 'a = x
val 'a pair_up : 'a -> 'a * 'a = fn x => (x, x)
fun ('a, 'b) swap (x : 'a, y : 'b) : 'b * 'a = (y, x)

(* ── Type expressions ── *)
type fn_type = int -> int -> int
type tuple_type = int * string * real
type record_type = { a : int, b : string list }
type app_type = (int, string) assoc
type nested_type = (int * int) list option
type unit_type = unit
type ''a eqt = ''a list

(* ── Datatype forms: replication, withtype, op constructors, mutual recursion ── *)
datatype color = Red | Green | Blue
datatype shade = datatype color
datatype 'a rose = Rose of 'a * 'a forest
and 'a forest = Forest of 'a rose list
datatype named = Named of name_t withtype name_t = string
datatype opcons = op Cons of int | Plain
val list_via_op = op:: (1, [2, 3])
val cons_pairs = ListPair.map op:: ([1, 2], [[3], [4]])
val plus_op = op+ (1, 2)
val minus_op = (op - (5, 3), op * (2, 3))

(* ── Exceptions: renaming, generative and carrying values ── *)
exception Missing = Empty
exception Wrapped of exn
exception Pair of int * int
val raised = (raise Fail "boom") handle Fail m => m | Pair (a, b) => Int.toString (a + b)
val chained = (Option.valOf NONE) handle Option => 0 | Match => 1 | Bind => 2 | Div => 3 | Overflow => 4 | Subscript => 5 | Size => 6 | Chr => 7 | Domain => 8
val named_handler = (1 div 0) handle e => (print (General.exnName e ^ ": " ^ General.exnMessage e ^ "\n"); 0)

(* ── Declaration sequences with and, val rec and fun with infix definition ── *)
val a1 = 1 and b1 = 2 and c1 = 3
val rec even = fn 0 => true | n => odd (n - 1)
and odd = fn 0 => false | n => even (n - 1)
fun even' 0 = true | even' n = odd' (n - 1)
and odd' 0 = false | odd' n = even' (n - 1)
infix 4 ++
fun a ++ b = a + b
fun (a ++ b) = a + b
fun op ++ (a, b) = a + b
infix 7 **
fun x ** y = x * y
infixr 0 $
fun f $ x = f x
val dollar_use = Int.toString $ 1 + 2 ** 3 ++ 4
infixr 5 @@
val (op @@) = fn (a, b) => a @ b
fun curried_infix (x : int) (y : int) : int = x + y
fun tupled_clausal (0, _) = "zero"
  | tupled_clausal (_, 0) = "zero"
  | tupled_clausal _ = "nonzero"

(* ── Expression forms: sequence, case nesting, if chains, while with refs ── *)
val sequence_expr = (print "a"; print "b"; 3)
val nested_case = case (1, "x") of
    (0, _) => "zero"
  | (n, "x") => (case n of 1 => "one-x" | _ => "other-x")
  | _ => "other"
val if_chain = if true then 1 else if false then 2 else 3
val let_sequence = let val x = 1 in print "in"; x + 1; x + 2 end
val let_multi = let val x = 1 val y = 2; fun f z = z + x + y in f 3 end
val local_in_let = let local val k = 5 in val m = k * 2 end in m end
val selector_fn = (#a { a = 1, b = 2 }, #1 ("x", 2))
val record_update_style = let val { sku, ... } = hd [{ sku = "a", n = 1 }] in { sku = sku, n = 2 } end
val ref_cell = ref 10
val deref_assign = (ref_cell := !ref_cell + 1; !ref_cell)
val negation = ~ 5 + abs ~3
val unit_pattern = (fn () => "unit") ()
val wildcard_val = (fn _ => 0) "ignored"
val bool_ops = (true andalso false) orelse (not false)
val chars = (Char.ord #"a", Char.chr 98, Char.isDigit #"7", Char.toString #"z", str #"q")
val reals = (Real.floor 2.5, Real.round 2.5, Real.trunc ~2.5, Real.fromInt 3, Math.sqrt 16.0, Math.pi)
val strings = (String.size "abc", String.substring ("hello", 1, 3), String.explode "hi", String.implode [#"o", #"k"], String.concat ["a", "b"], String.tokens Char.isSpace "a b  c")
val options = (SOME 1, NONE : int option, Option.getOpt (NONE, 5), Option.map (fn x => x + 1) (SOME 1))
val vectors = (Vector.fromList [1, 2, 3], Vector.sub (Vector.fromList [10, 20], 0))
val arrays = let val arr = Array.array (3, 0) in Array.update (arr, 0, 9); Array.sub (arr, 0) end
val word_math = (Word.toInt (Word.andb (0wxFF, 0w15)), Word.toString (Word.<< (0w1, 0w4)))
val tuple_projection = (#1 (1, 2), #2 (1, 2))
val text_io = (TextIO.output (TextIO.stdOut, "out\n"); TextIO.flushOut TextIO.stdOut)
val time_now = Time.toSeconds (Time.now ())
val cmd_line = CommandLine.arguments ()

(* ── Structures: nested, transparent and opaque ascription, where type, signature with exception ── *)
signature COUNTER =
sig
  type t
  val zero : t
  val inc : t -> t
  val toInt : t -> int
  exception Overflow_
  datatype ('a) wrapper = W of 'a
  structure Sub : sig type u val make : unit -> u end
  sharing type t = Sub.u
end

structure Transparent : ORDERED = IntOrd
structure Opaque :> ORDERED where type t = int = IntOrd
structure Alias = IntOrd
structure Nested =
struct
  structure Deep = struct val v = 1 end
  val w = Deep.v + 1
  open Deep
  local val hidden = 3 in val shown = hidden end
end
val nested_access = Nested.Deep.v + Nested.w + Nested.shown + Nested.v

(* ── Functors: all parameter forms, applications, transparent and opaque result ── *)
functor Pairing (type a type b val show_a : a -> string val show_b : b -> string) =
struct
  fun show (x : a, y : b) = show_a x ^ "/" ^ show_b y
end
functor Twice (X : sig val f : int -> int end) :> sig val twice : int -> int end =
struct
  fun twice n = X.f (X.f n)
end
functor Sorted (Elt : ORDERED) : sig val sort : Elt.t list -> Elt.t list end =
struct
  fun sort [] = []
    | sort (p :: rest) =
        let
          val (lo, hi) = List.partition (fn y => Elt.compare (y, p) = LESS) rest
        in
          sort lo @ [p] @ sort hi
        end
end
structure IntPairing = Pairing (type a = int type b = string val show_a = Int.toString val show_b = fn s => s)
structure Doubler = Twice (struct fun f n = n * 2 end)
structure IntSorted = Sorted (IntOrd)
structure SortedBody = Sorted (struct type t = int val compare = Int.compare end)

(* ── Signature specs: val, type with definition, eqtype, datatype replication, exception, structure ── *)
signature RICH =
sig
  eqtype key
  type 'a table
  type name = string
  type ('a, 'b) pair2 = 'a * 'b
  datatype shape = Circle of real | Square of real
  datatype color_copy = datatype color
  exception NotFound of key
  val empty : 'a table
  val insert : key * 'a * 'a table -> 'a table
  val lookup : key * 'a table -> 'a option
  structure Util : sig type t val id : t -> t end
  sharing type key = Util.t
end
signature LOCAL_SIG = RICH where type key = int where type 'a table = 'a list
signature WITH_INCLUDE = sig include ORDERED val extra : t end

(* ── Top-level expressions and the it binding ── *)
1 + 2;
print "top-level expression\n";
val it_use = it

(* ── Main ── *)
val items : item list =
  [ { sku = "ABC-1", name = "Hammer", quantity = 12, status = Paid 20.5 }
  , { sku = "ABC-2", name = "Nails", quantity = 400, status = Shipped ("DHL", 2) }
  , { sku = "ABC-3", name = "Saw", quantity = 3, status = Cancelled "duplicate" } ]

val () = List.app (fn i => print (describe i ^ "\n")) items
val () = print ("total quantity: " ^ Int.toString (List.foldl (fn (i : item, a) => a + #quantity i) 0 items) ^ "\n")
val () = print (Real.fmt (StringCvt.FIX (SOME 2)) 3.14159 ^ "\n")
val _ = OS.Process.exit OS.Process.success
