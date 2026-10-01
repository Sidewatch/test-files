(* OCaml showcase: variants, records, modules, functors, GADTs, objects and effects. *)
(* A comment (* with a nested comment *) still going *)
(** A documentation comment for [status].
    @param x the input
    @return the output
    @raise Not_found when missing
    @see <https://example.com> the spec
    @since 4.14 *)
(*** A second-level doc comment ***)
(* TODO: persist orders *)
(* FIXME: totals use floats, not decimals *)
(* "a string inside a comment" and 'c' *)

#use "topfind";;
#require "str";;
#directory "_build";;
[@@@ocaml.warning "-32-33"]
[@@@warning "-unused-var-strict"]

open Printf
open! Stdlib
module L = List
module type SHOW = sig type t val show : t -> string end
include Stdlib.Option

(* ── Literals ── *)
let int_dec = 1_000_000
let int_hex = 0xFF_EC
let int_oct = 0o755
let int_bin = 0b1010_1010
let int_neg = -42
let int32_lit = 42l
let int64_lit = 42L
let native_lit = 42n
let float_lit = 3.14
let float_exp = 1.5e-3
let float_hex = 0x1.8p3
let float_us = 1_000.5
let float_nan = nan
let float_inf = infinity
let float_ninf = neg_infinity
let bool_t = true and bool_f = false
let unit_v = ()
let char_a = 'a'
let char_esc = '\n'
let char_quote = '\''
let char_dec = '\065'
let char_hex = '\x41'
let char_oct = '\o101'
let str_plain = "tab:\t newline:\n quote:\" backslash:\\ dec:\065 hex:\x41 oct:\o101 uni:\u{00e9}"
let str_cont = "line one \
                continued"
let str_quoted = {|a quoted string with "quotes" and \n literal|}
let str_quoted_id = {id|can contain |} safely|id}
let list_lit = [ 1; 2; 3 ]
let array_lit = [| 1; 2; 3 |]
let tuple_lit = (1, "two", 3.0)
let poly_variant = `Tag
let poly_payload = `Pair (1, 2)

(* ── Types ── *)
type status = Pending | Paid of float | Cancelled of string
type order = { number : int; total : float; mutable status : status }
type 'a tree = Leaf | Node of 'a tree * 'a * 'a tree
type ('k, 'v) assoc = ('k * 'v) list
type point = { x : float; y : float } [@@deriving show, eq]
type color = Red | Green | Blue [@@deriving enum]
type _ expr =
  | Int : int -> int expr
  | Bool : bool -> bool expr
  | Add : int expr * int expr -> int expr
  | If : bool expr * 'a expr * 'a expr -> 'a expr
type shape = [ `Circle of float | `Square of float ]
type t = private int
type u = A | B of { name : string; qty : int }
type ('a, 'b) either = L of 'a | R of 'b
type extensible = ..
type extensible += Extra of string
exception Out_of_stock of string
exception Invalid of { sku : string; reason : string }

(* ── Functions and pattern matching ── *)
let describe = function
  | { number; status = Pending; _ } -> sprintf "#%d pending" number
  | { number; status = Paid on; _ } -> sprintf "#%d paid (%.0f)" number on
  | { number; status = Cancelled reason; _ } when reason <> "" -> sprintf "#%d cancelled: %s" number reason
  | { number; _ } -> sprintf "#%d cancelled" number

let rec fact n = if n <= 1 then 1 else n * fact (n - 1)
and is_even n = n = 0 || is_odd (n - 1)
and is_odd n = n <> 0 && is_even (n - 1)

let add ?(step = 1) ~base x = base + (x * step)
let opt_arg ?label () = match label with Some l -> l | None -> "none"
let apply f x = f x
let compose f g x = f (g x)
let ( |> ) x f = f x
let ( ++ ) a b = a ^ b
let ( let* ) = Option.bind
let ( and* ) a b = match a, b with Some x, Some y -> Some (x, y) | _ -> None
let ( .%() ) a i = a.(i)
let revenue orders =
  List.fold_left (fun acc o -> match o.status with Paid _ -> acc +. o.total | _ -> acc) 0.0 orders

let classify n =
  match n with
  | 0 -> "zero"
  | 1 | 2 | 3 -> "few"
  | n when n < 0 -> "negative"
  | _ -> "many"

let first_two = function a :: b :: _ -> Some (a, b) | [ _ ] | [] -> None
let arr_match = function [| a; b |] -> a + b | _ -> 0
let lazy_pat = function lazy v -> v
let as_pat = function (Some _ as whole) -> whole | None -> None
let exn_pat f = match f () with v -> v | exception Not_found -> 0
let char_range c = match c with 'a' .. 'z' -> true | _ -> false
let rec eval : type a. a expr -> a = function
  | Int n -> n
  | Bool b -> b
  | Add (a, b) -> eval a + eval b
  | If (c, t, e) -> if eval c then eval t else eval e

(* ── Operators and expressions ── *)
let arith = (1 + 2 - 3) * 4 / 2 mod 3
let farith = (1.0 +. 2.0 -. 3.0) *. 4.0 /. 2.0 ** 2.0
let cmp = 1 < 2 && 2 <= 2 || 3 > 4 && not (4 >= 5)
let eq = 1 = 1 && 2 <> 3 && "a" == "a" && "b" != "c"
let bits = (0xF0 land 0x3C) lor (1 lsl 4) lxor (256 lsr 2) lor (-8 asr 1) lor lnot 0
let concat = "a" ^ "b"
let cons = 1 :: 2 :: []
let appended = [ 1 ] @ [ 2 ]
let deref = let r = ref 0 in r := !r + 1; !r
let field_set (o : order) = o.status <- Pending
let array_get a = a.(0) + a.(1)
let array_set a = a.(0) <- 5
let string_get s = s.[0]
let bigarray b = b.{0}
let seq_expr = print_string "a"; print_string "b"
let tern = if true then 1 else 2
let tup_let = let (a, b) = (1, 2) in a + b
let rec_let = let rec go n = if n = 0 then 0 else go (n - 1) in go 10
let local_open = Printf.(sprintf "%d" 5)
let local_open2 = let open List in length [ 1; 2 ]
let fun_kw = fun x y -> x + y
let fun_labels = fun ~a ~(b : int) ?(c = 0) () -> a + b + c
let coerce = (`Circle 1.0 :> shape)
let constraint_ = (5 : int)
let lazy_v = lazy (print_endline "forced"; 42)
let forced = Lazy.force lazy_v
let assertion = assert (1 + 1 = 2)
let poly_use = function `Circle r -> r | `Square s -> s
let pipe = [ 1; 2; 3 ] |> List.map (fun x -> x * x) |> List.filter (fun x -> x > 1)
let letop = let* a = Some 1 and* b = Some 2 in Some (a + b)
let printf_fmt = printf "%d %s %5.2f %c %b %x %%\n" 1 "a" 2.0 'c' true 255
let format_str = Format.asprintf "@[<v>%a@]@." Format.pp_print_int 1

(* ── Control flow ── *)
let loops () =
  for i = 0 to 9 do print_int i done;
  for i = 9 downto 0 do print_int i done;
  let n = ref 0 in
  while !n < 5 do incr n done;
  try
    ignore (List.assoc "x" [ ("y", 1) ]);
    raise (Out_of_stock "A-100")
  with
  | Not_found -> print_endline "nf"
  | Out_of_stock sku -> prerr_endline sku
  | Invalid { sku; _ } -> prerr_endline sku
  | Failure msg | Invalid_argument msg -> prerr_endline msg
  | e -> raise e

(* ── Modules, functors, signatures ── *)
module StatusSet = Set.Make (String)

module type STACK = sig
  type 'a t
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  val pop : 'a t -> ('a * 'a t) option
  exception Empty
  module Inner : sig val n : int end
end

module Stack : STACK = struct
  type 'a t = 'a list
  let empty = []
  let push = List.cons
  let pop = function [] -> None | x :: r -> Some (x, r)
  exception Empty
  module Inner = struct let n = 0 end
end

module MakeShow (S : SHOW) : sig val all : S.t list -> string end = struct
  let all xs = String.concat ", " (List.map S.show xs)
end

module IntShow = MakeShow (struct type t = int let show = string_of_int end)
module M = struct include Stack end
module rec Even : sig val f : int -> bool end = struct let f n = n = 0 || Odd.f (n - 1) end
and Odd : sig val f : int -> bool end = struct let f n = n <> 0 && Even.f (n - 1) end
let first_class = (module Stack : STACK)
let unpack = let module S = (val first_class) in S.empty
module type S2 = sig include STACK with type 'a t = 'a list end
module Alias = Stdlib.List
open struct let hidden = 1 end

(* ── Objects and classes ── *)
class counter (init : int) =
  object (self)
    val mutable n = init
    val label = "counter"
    method incr = n <- n + 1; self
    method get = n
    method private secret = 42
    initializer print_endline "created"
  end

class virtual shape_c =
  object
    method virtual area : float
  end

class circle r = object inherit shape_c method area = 3.14 *. r *. r end
class type point_t = object method x : int end
let obj = object method hello = "hi" end
let c = new counter 0
let n = c#incr#get
let dup = Oo.copy c

(* ── Attributes and extensions ── *)
let[@inline] fast x = x + 1
let f = fun [@warning "-27"] x y -> x
let%test_unit "adds" = assert (fast 1 = 2)
let ext = [%expr 1 + 2]
[%%define flag]
let _ = [%ext payload]
external caml_hash : int -> int = "caml_hash_stub" [@@noalloc]

(* ── Effects (OCaml 5) ── *)
type _ Effect.t += Ask : string Effect.t
let run_effect () =
  Effect.Deep.match_with (fun () -> Effect.perform Ask) ()
    { retc = Fun.id; exnc = raise; effc = (fun (type a) (e : a Effect.t) -> match e with Ask -> Some (fun (k : (a, _) Effect.Deep.continuation) -> Effect.Deep.continue k "answer") | _ -> None) }

(* ── More OCaml: keywords, directives and rarely used forms ── *)
# 1 "generated.ml"
#show_type;;
#trace fact;;
let begin_end = begin 1 + 2 end
let local_exception = let exception Local of int in try raise (Local 1) with Local n -> n
let local_module = let module M = struct let v = 5 end in M.v
let object_copy = object val x = 1 method clone = {< x = 2 >} end
let cmp_ops = compare 1 2 = 0 || max 1 2 > min 1 2 || 1 <> 2
let and_or = true or false
let amp = true & false
let physical = ref 1 == ref 1
let nested_fun = fun x -> fun y -> fun z -> x + y + z
let tuple_fun = fun (a, b) -> a + b
let record_fun = fun { number; _ } -> number
let optional_default = fun ?(x = 1) ?y () -> x
let labelled_call = add ~base:1 ~step:2 3
let punned = let base = 1 and step = 2 in add ~base ~step 3
let optional_pass = add ?step:(Some 2) ~base:1 3
let method_call = (object method m = 1 end)#m
let infix_ops = 1 +. 2. -. 3. *. 4. /. 5. ** 6.
let user_ops = let ( >>= ) = Option.bind and ( <|> ) a b = match a with Some _ -> a | None -> b in Some 1 >>= fun x -> Some x <|> None
let bang_ops = let ( !! ) x = x and ( *** ) a b = a * b in !!1 *** 2
let string_ops = String.length "abc" + String.get "abc" 0 |> Char.code
let char_ops = Char.chr 65 |> Char.escaped
let array_ops = Array.init 3 (fun i -> i * i) |> Array.map succ |> Array.to_list
let hashtbl = let h = Hashtbl.create 16 in Hashtbl.replace h "k" 1; Hashtbl.find_opt h "k"
let buffer = let b = Buffer.create 16 in Buffer.add_string b "x"; Buffer.contents b
let string_fmt = Printf.sprintf "%S %s %i %u %ld %Ld %nd %f %F %g %B %c %C %a %t %!" "q" "s" 1 2 3L 4L 5n 1.0 2.0 3.0 true 'c' 'd' (fun _ _ -> ()) (fun _ -> ())
let seq_ops = Seq.(init 3 (fun i -> i) |> map succ |> fold_left ( + ) 0)
let result_ops = Result.(bind (ok 1) (fun x -> if x > 0 then Ok x else Error "neg"))
let lazy_list = let rec nat n = lazy (Cons (n, nat (n + 1))) and _ = () in ignore nat
let polymorphic_compare = (1, "a") < (2, "b")
let exception_match = match Sys.getenv "HOME" with s -> s | exception Not_found -> "none"
let while_for = let r = ref 0 in for i = 1 to 3 do for j = i downto 1 do r := !r + j done done; while !r > 0 do decr r done; !r
let if_no_else = if true then print_string "x"
let semicolon_seq = (print_string "a"; print_string "b"; ())
let mod_ops = 7 mod 3 + (-7) mod 3
let shift_ops = 1 lsl 3 + 16 lsr 2 + (-16) asr 2
let float_conv = float_of_int 3 +. Float.of_int 4 |> int_of_float
let unit_pat = fun () -> ()
let wildcard = fun _ -> 0
let or_pat = function 1 | 2 | 3 -> true | _ -> false
let interval_pat = function 'a' .. 'z' -> 1 | 'A' .. 'Z' -> 2 | _ -> 0
let tuple_pat = function (0, _) -> 0 | (_, 0) -> 1 | (a, b) -> a + b
let nested_pat = function Some (Some x) -> x | Some None | None -> 0
let record_pat = function { x = 0.; y } | { x = _; y } -> y
let cons_pat = function x :: y :: rest -> x + y + List.length rest | _ -> 0
let constraint_pat = function (x : int) -> x
let alias_pat = function (_, _) as p -> p
let poly_pat = function `A -> 1 | `B n -> n | #shape -> 0
let rec_poly : [< `A | `B of int ] -> int = function `A -> 1 | `B n -> n
let exception_pat = function exception End_of_file -> 0 | x -> x
let unreachable = function (x : empty) -> (.)
let first_class_module_pat = fun (module M : STACK) -> M.empty
let open_pat = function M.(Some x) -> x | _ -> 0
let ref_pat = function { contents = c } -> c
let type_annot : int -> int = fun x -> x
let poly_annot : 'a. 'a -> 'a = fun x -> x
let locally_abstract (type a) (x : a) : a = x
let rec_value = let rec xs = 1 :: xs in xs
let object_type : < m : int; n : string > = object method m = 1 method n = "s" end
let variant_type : [ `A | `B ] = `A
let class_type_use : point_t = object method x = 1 end
let attr_item = (42 [@attr] [@another payload])
let ext_node = [%ext 1 + 2]
let quoted_ext = {%ext|raw payload|}
let ppx_let = let%ext x = 1 in x
let ppx_match = match%ext 1 with _ -> ()
[@@@attr_floating]
[%%ext_item]
let () = ()

let () =
  let orders = [ { number = 1; total = 120.5; status = Paid 20260924. }
               ; { number = 2; total = 0.; status = Cancelled "duplicate" }
               ; { number = 3; total = 42.; status = Pending } ] in
  List.iter (fun o -> print_endline (describe o)) orders;
  Printf.printf "revenue: %.2f\n" (revenue orders)
