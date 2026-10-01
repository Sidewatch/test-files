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

(* ── Main ── *)
val items : item list =
  [ { sku = "ABC-1", name = "Hammer", quantity = 12, status = Paid 20.5 }
  , { sku = "ABC-2", name = "Nails", quantity = 400, status = Shipped ("DHL", 2) }
  , { sku = "ABC-3", name = "Saw", quantity = 3, status = Cancelled "duplicate" } ]

val () = List.app (fn i => print (describe i ^ "\n")) items
val () = print ("total quantity: " ^ Int.toString (List.foldl (fn (i : item, a) => a + #quantity i) 0 items) ^ "\n")
val () = print (Real.fmt (StringCvt.FIX (SOME 2)) 3.14159 ^ "\n")
val _ = OS.Process.exit OS.Process.success
