;; ── Comments ───────────────────────────────────────────────
;; WebAssembly text: a warehouse stock module.
;; TODO: add bulk-memory zeroing. FIXME: bounds checks.
(; Block comment
   (; nested block comments are allowed ;)
   still inside ;)

(module $warehouse
  ;; ── Types ────────────────────────────────────────────────
  (type $binop (func (param i32 i32) (result i32)))
  (type $pair  (func (param $a i32) (param $b i32) (result i32 i32)))
  (type $void  (func))
  (type $cb    (func (param i32) (result i32)))
  (rec
    (type $node (struct (field $value i32) (field $next (ref null $node))))
    (type $vec  (array (mut i8))))

  ;; ── Imports ──────────────────────────────────────────────
  (import "env" "log" (func $log (param i32)))
  (import "env" "memory" (memory $env_mem 1 4))
  (import "env" "table" (table $env_tab 4 funcref))
  (import "env" "limit" (global $limit i32))
  (import "env" "counter" (global $counter (mut i32)))
  (import "env" "error" (tag $error (param i32)))

  ;; ── Memory, tables, data, elements ───────────────────────
  (memory $mem (export "mem") 1 16)
  (memory $shared 1 2 shared)
  (table $tbl 4 funcref)
  (table $refs 2 externref)
  (elem (table $tbl) (i32.const 0) func $add $fact)
  (elem $passive func $add $fact)
  (elem declare func $bump)
  (data $greeting (i32.const 0) "hello")
  (data (i32.const 16) "tab\t newline\n quote\" backslash\\ hex\41\42 unicode\u{263A}\u{1F4E6}")
  (data $passive_data "raw bytes \00\01\ff")

  ;; ── Globals ──────────────────────────────────────────────
  (global $count (mut i32) (i32.const 0))
  (global $reorder_point i32 (i32.const 25))
  (global $ratio f64 (f64.const 0.75))
  (global $big i64 (i64.const 1_000_000))
  (global $exported (export "reorder") i32 (i32.const 25))

  ;; ── Numbers ──────────────────────────────────────────────
  (func $numbers (result f64)
    (drop (i32.const 42))
    (drop (i32.const -42))
    (drop (i32.const 0xFF_FF))
    (drop (i32.const +7))
    (drop (i64.const 0x7fff_ffff_ffff_ffff))
    (drop (i64.const -9223372036854775808))
    (drop (f32.const 3.14))
    (drop (f32.const 1e-3))
    (drop (f32.const 0x1.8p3))
    (drop (f32.const nan))
    (drop (f32.const nan:0x200000))
    (drop (f32.const -inf))
    (drop (f64.const 1.5e10))
    (drop (f64.const 0x1.fffffffffffffp+1023))
    (drop (f64.const inf))
    (drop (f64.const -nan))
    (f64.const 0x1p-1022))

  ;; ── Functions: arithmetic ────────────────────────────────
  (func $add (export "add") (type $binop)
    local.get 0
    local.get 1
    i32.add)

  (func $bump (export "bump") (param $by i32) (result i32)
    (global.set $count (i32.add (global.get $count) (local.get $by)))
    (global.get $count))

  (func $fact (export "fact") (param $n i64) (result i64)
    (if (result i64) (i64.le_u (local.get $n) (i64.const 1))
      (then (i64.const 1))
      (else (i64.mul (local.get $n) (call $fact (i64.sub (local.get $n) (i64.const 1)))))))

  (func $ops (param $a i32) (param $b i32) (result i32)
    (local $t i32)
    (local $f f32) (local $d f64) (local $l i64)
    ;; integer arithmetic and bitwise
    (local.set $t (i32.add (local.get $a) (local.get $b)))
    (local.set $t (i32.sub (local.get $t) (i32.const 1)))
    (local.set $t (i32.mul (local.get $t) (i32.const 2)))
    (local.set $t (i32.div_s (local.get $t) (i32.const 3)))
    (local.set $t (i32.div_u (local.get $t) (i32.const 3)))
    (local.set $t (i32.rem_s (local.get $t) (i32.const 5)))
    (local.set $t (i32.rem_u (local.get $t) (i32.const 5)))
    (local.set $t (i32.and (local.get $t) (i32.const 0xff)))
    (local.set $t (i32.or (local.get $t) (i32.const 1)))
    (local.set $t (i32.xor (local.get $t) (i32.const 2)))
    (local.set $t (i32.shl (local.get $t) (i32.const 1)))
    (local.set $t (i32.shr_s (local.get $t) (i32.const 1)))
    (local.set $t (i32.shr_u (local.get $t) (i32.const 1)))
    (local.set $t (i32.rotl (local.get $t) (i32.const 1)))
    (local.set $t (i32.rotr (local.get $t) (i32.const 1)))
    (local.set $t (i32.clz (local.get $t)))
    (local.set $t (i32.ctz (local.get $t)))
    (local.set $t (i32.popcnt (local.get $t)))
    (local.set $t (i32.extend8_s (local.get $t)))
    ;; comparisons
    (drop (i32.eqz (local.get $t)))
    (drop (i32.eq (local.get $a) (local.get $b)))
    (drop (i32.ne (local.get $a) (local.get $b)))
    (drop (i32.lt_s (local.get $a) (local.get $b)))
    (drop (i32.lt_u (local.get $a) (local.get $b)))
    (drop (i32.gt_s (local.get $a) (local.get $b)))
    (drop (i32.gt_u (local.get $a) (local.get $b)))
    (drop (i32.le_s (local.get $a) (local.get $b)))
    (drop (i32.ge_u (local.get $a) (local.get $b)))
    ;; floats
    (local.set $d (f64.sqrt (f64.const 2)))
    (local.set $d (f64.add (local.get $d) (f64.mul (f64.const 1.5) (f64.neg (local.get $d)))))
    (local.set $d (f64.min (local.get $d) (f64.max (f64.floor (local.get $d)) (f64.ceil (local.get $d)))))
    (local.set $d (f64.copysign (f64.abs (local.get $d)) (f64.trunc (local.get $d))))
    (local.set $f (f32.demote_f64 (local.get $d)))
    (local.set $d (f64.promote_f32 (local.get $f)))
    (local.set $l (i64.extend_i32_s (local.get $t)))
    (local.set $t (i32.wrap_i64 (local.get $l)))
    (local.set $d (f64.convert_i32_s (local.get $t)))
    (local.set $t (i32.trunc_f64_s (local.get $d)))
    (local.set $t (i32.trunc_sat_f64_u (local.get $d)))
    (local.set $t (i32.reinterpret_f32 (local.get $f)))
    (drop (f32.nearest (local.get $f)))
    (drop (select (i32.const 1) (i32.const 2) (local.get $t)))
    (drop (select (result i32) (i32.const 1) (i32.const 2) (local.get $t)))
    (local.tee $t (local.get $t))
    (nop))

  ;; ── Control flow ─────────────────────────────────────────
  (func $control (param $n i32) (result i32)
    (local $sum i32)
    (block $done
      (loop $again
        (br_if $done (i32.ge_u (local.get $sum) (local.get $n)))
        (local.set $sum (i32.add (local.get $sum) (i32.const 1)))
        (br $again)))
    (block $outer (result i32)
      (block $a
        (block $b
          (br_table $a $b $outer (local.get $n))))
      (i32.const 1))
    drop
    (if (i32.eqz (local.get $n))
      (then (return (i32.const 0))))
    (if (local.get $n) (then nop) (else unreachable))
    ;; flat (stack) form
    local.get $n
    if (result i32)
      i32.const 1
    else
      i32.const 2
    end
    local.get $sum
    i32.add)

  (func $try (param $v i32) (result i32)
    (try (result i32)
      (do (if (result i32) (local.get $v) (then (throw $error (local.get $v))) (else (i32.const 0))))
      (catch $error)
      (catch_all (i32.const -1))))

  ;; ── Calls, tables ────────────────────────────────────────
  (func $indirect (param $i i32) (result i32)
    (call_indirect $tbl (type $binop) (i32.const 1) (i32.const 2) (local.get $i)))

  (func $tail (param $n i32) (result i32)
    (return_call $add (local.get $n) (i32.const 1)))

  (func $refs (param $r funcref) (result i32)
    (drop (ref.func $add))
    (drop (ref.null func))
    (drop (ref.null extern))
    (ref.is_null (local.get $r)))

  (func $multi (type $pair)
    local.get $a
    local.get $b)

  ;; ── Memory ───────────────────────────────────────────────
  (func (export "store") (param $addr i32) (param $value i32)
    (i32.store (local.get $addr) (local.get $value))
    (i32.store8 offset=4 (local.get $addr) (local.get $value))
    (i32.store16 offset=8 align=2 (local.get $addr) (local.get $value))
    (i64.store offset=16 align=8 (local.get $addr) (i64.const 1)))

  (func (export "load") (param $addr i32) (result i32)
    (drop (i32.load8_u (local.get $addr)))
    (drop (i32.load16_s offset=2 (local.get $addr)))
    (drop (i64.load32_u (local.get $addr)))
    (drop (f64.load (local.get $addr)))
    (drop (memory.size))
    (drop (memory.grow (i32.const 1)))
    (memory.fill (local.get $addr) (i32.const 0) (i32.const 16))
    (memory.copy (i32.const 0) (local.get $addr) (i32.const 16))
    (memory.init $passive_data (i32.const 0) (i32.const 0) (i32.const 4))
    (data.drop $passive_data)
    (i32.load (local.get $addr)))

  ;; ── SIMD and atomics ─────────────────────────────────────
  (func $simd (param $v v128) (result v128)
    (i32x4.add (local.get $v) (v128.const i32x4 1 2 3 4))
    (i8x16.splat (i32.const 7))
    (f32x4.mul (v128.const f32x4 1.0 2.0 3.0 4.0) (f32x4.splat (f32.const 2)))
    (i8x16.shuffle 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 (local.get $v) (local.get $v))
    (drop (i32x4.extract_lane 0 (local.get $v)))
    (drop (v128.any_true (local.get $v)))
    (v128.xor (local.get $v) (local.get $v)))

  (func $atomic (param $addr i32) (result i32)
    (drop (memory.atomic.notify (local.get $addr) (i32.const 1)))
    (drop (i32.atomic.rmw.add (local.get $addr) (i32.const 1)))
    (drop (i32.atomic.rmw.cmpxchg (local.get $addr) (i32.const 0) (i32.const 1)))
    (atomic.fence)
    (i32.atomic.load (local.get $addr)))

  ;; ── Annotations and start ────────────────────────────────
  (@custom "name-hint" (after func) "stock")
  (func $init (@name "init") (call $log (i32.const 1)))

  (export "table" (table $tbl))
  (export "global" (global $count))
  (tag $err (param i32))
  ;; ── Inline imports/exports and abbreviations ─────────────
  (func $inline_import (import "env" "tick") (param i32) (result i32))
  (func $inline_export (export "a") (export "b") (result i32) (i32.const 1))
  (table $abbr (export "abbr") funcref (elem $add $fact))
  (memory $abbr_mem (export "abbr_mem") (data "inline data" "\00\01"))
  (global $inline_g (export "g") (import "env" "g") i32)
  (global $ext_const i32 (i32.add (global.get $limit) (i32.const 1)))

  ;; ── Reference types and table instructions ───────────────
  (func $table_ops (param $i i32) (result funcref)
    (table.set $tbl (local.get $i) (ref.func $add))
    (drop (table.size $tbl))
    (drop (table.grow $tbl (ref.null func) (i32.const 1)))
    (table.fill $tbl (i32.const 0) (ref.null func) (i32.const 2))
    (table.copy $tbl $tbl (i32.const 0) (i32.const 1) (i32.const 1))
    (table.init $tbl $passive (i32.const 0) (i32.const 0) (i32.const 2))
    (elem.drop $passive)
    (table.get $tbl (local.get $i)))

  ;; ── Exceptions (legacy and new forms) ────────────────────
  (func $exceptions (param $v i32)
    (block $handler (result i32)
      (try_table (catch $err $handler) (catch_ref $err $handler) (catch_all $handler) (catch_all_ref $handler)
        (throw $err (local.get $v))))
    drop
    (try
      (do (throw $err (i32.const 1)))
      (catch $err drop)
      (delegate 0))
    (try (do) (catch_all (rethrow 0)))
    (throw_ref (ref.null exn)))

  ;; ── Typed function references and GC ─────────────────────
  (func $typed (param $f (ref null $cb)) (result i32)
    (call_ref $cb (i32.const 1) (local.get $f))
    (return_call_ref $cb (i32.const 2) (local.get $f)))
  (func $indirect_tail (param $i i32) (result i32)
    (return_call_indirect (type $binop) (i32.const 1) (i32.const 2) (local.get $i)))
  (func $gc (param $n (ref null $node)) (result i32)
    (local $v (ref $vec))
    (local $o (ref null any))
    (local.set $v (array.new $vec (i32.const 0) (i32.const 8)))
    (local.set $v (array.new_default $vec (i32.const 8)))
    (local.set $v (array.new_fixed $vec 2 (i32.const 1) (i32.const 2)))
    (local.set $v (array.new_data $vec $passive_data (i32.const 0) (i32.const 4)))
    (array.set $vec (local.get $v) (i32.const 0) (i32.const 7))
    (drop (array.get_u $vec (local.get $v) (i32.const 0)))
    (drop (array.len (local.get $v)))
    (array.fill $vec (local.get $v) (i32.const 0) (i32.const 0) (i32.const 4))
    (array.copy $vec $vec (local.get $v) (i32.const 0) (local.get $v) (i32.const 1) (i32.const 2))
    (drop (struct.new $node (i32.const 1) (ref.null $node)))
    (drop (struct.new_default $node))
    (drop (struct.get $node $value (local.get $n)))
    (struct.set $node $value (local.get $n) (i32.const 3))
    (drop (ref.test (ref $node) (local.get $o)))
    (drop (ref.cast (ref null $node) (local.get $o)))
    (drop (ref.i31 (i32.const 1)))
    (drop (i31.get_s (ref.i31 (i32.const 1))))
    (drop (ref.eq (local.get $o) (local.get $o)))
    (drop (ref.as_non_null (local.get $n)))
    (block $b (result (ref null any))
      (br_on_null $b (local.get $n))
      (br_on_non_null $b (local.get $n))
      (br_on_cast $b (ref null any) (ref $node) (local.get $o))
      (br_on_cast_fail $b (ref null any) (ref $node) (local.get $o))
      drop
      (ref.null any))
    drop
    (drop (any.convert_extern (extern.convert_any (local.get $o))))
    (i32.const 0))

  ;; ── Threads, bulk memory, extended const, memory64 ───────
  (memory $big i64 1 65536)
  (func $threads (param $a i32) (result i32)
    (drop (memory.atomic.wait32 (local.get $a) (i32.const 0) (i64.const -1)))
    (drop (memory.atomic.wait64 (local.get $a) (i64.const 0) (i64.const -1)))
    (drop (i32.atomic.rmw8.add_u (local.get $a) (i32.const 1)))
    (drop (i32.atomic.rmw16.sub_u (local.get $a) (i32.const 1)))
    (drop (i64.atomic.rmw32.and_u (local.get $a) (i64.const 1)))
    (drop (i32.atomic.rmw.or (local.get $a) (i32.const 1)))
    (drop (i32.atomic.rmw.xor (local.get $a) (i32.const 1)))
    (drop (i32.atomic.rmw.xchg (local.get $a) (i32.const 1)))
    (i32.atomic.store8 (local.get $a) (i32.const 1))
    (i32.atomic.load16_u (local.get $a)))

  ;; ── More SIMD ────────────────────────────────────────────
  (func $simd2 (param $v v128) (param $w v128) (result v128)
    (drop (v128.load (i32.const 0)))
    (v128.store (i32.const 0) (local.get $v))
    (drop (v128.load8_splat (i32.const 0)))
    (drop (v128.load32_zero (i32.const 0)))
    (drop (v128.load16_lane 1 (i32.const 0) (local.get $v)))
    (drop (i16x8.replace_lane 0 (local.get $v) (i32.const 1)))
    (drop (i64x2.extract_lane 1 (local.get $v)))
    (drop (f64x2.splat (f64.const 1)))
    (drop (v128.const i8x16 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))
    (drop (v128.const i16x8 1 2 3 4 5 6 7 8))
    (drop (v128.const i64x2 1 2))
    (drop (v128.const f64x2 1.5 2.5))
    (drop (v128.and (local.get $v) (local.get $w)))
    (drop (v128.andnot (local.get $v) (local.get $w)))
    (drop (v128.or (local.get $v) (local.get $w)))
    (drop (v128.not (local.get $v)))
    (drop (v128.bitselect (local.get $v) (local.get $w) (local.get $v)))
    (drop (i8x16.swizzle (local.get $v) (local.get $w)))
    (drop (i8x16.eq (local.get $v) (local.get $w)))
    (drop (i32x4.lt_s (local.get $v) (local.get $w)))
    (drop (f32x4.ge (local.get $v) (local.get $w)))
    (drop (i16x8.mul (local.get $v) (local.get $w)))
    (drop (i32x4.dot_i16x8_s (local.get $v) (local.get $w)))
    (drop (i16x8.extmul_low_i8x16_s (local.get $v) (local.get $w)))
    (drop (i8x16.narrow_i16x8_u (local.get $v) (local.get $w)))
    (drop (i32x4.trunc_sat_f32x4_s (local.get $v)))
    (drop (f32x4.convert_i32x4_u (local.get $v)))
    (drop (i64x2.extend_low_i32x4_s (local.get $v)))
    (drop (i32x4.shl (local.get $v) (i32.const 1)))
    (drop (i8x16.popcnt (local.get $v)))
    (drop (i8x16.bitmask (local.get $v)))
    (drop (i32x4.all_true (local.get $v)))
    (drop (f32x4.relaxed_madd (local.get $v) (local.get $w) (local.get $v)))
    (drop (i8x16.relaxed_swizzle (local.get $v) (local.get $w)))
    (local.get $v))

  ;; ── Conventions: names, strings, comments ────────────────
  (func $name.with-many$chars!#%&'*+-/:<=>?@\^_`|~ (export "weird/name \u{1F4E6}") (param $p0 i32))
  (data (memory $mem) (offset (i32.const 100)) "offset form" "\n\t\r\\\"\'\0a\ff")
  (elem (table $tbl) (offset (i32.const 1)) funcref (ref.func $add) (item (ref.func $fact)))
  (elem $declared declare funcref (ref.func $bump))
  (start $init)
)
