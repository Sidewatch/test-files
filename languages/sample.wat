;; WebAssembly text: a memory-backed counter and a recursive factorial.
(module
  (memory (export "mem") 1)
  (global $count (mut i32) (i32.const 0))

  (func $bump (export "bump") (param $by i32) (result i32)
    (global.set $count (i32.add (global.get $count) (local.get $by)))
    (global.get $count))

  (func $fact (export "fact") (param $n i64) (result i64)
    (if (result i64) (i64.le_u (local.get $n) (i64.const 1))
      (then (i64.const 1))
      (else (i64.mul (local.get $n) (call $fact (i64.sub (local.get $n) (i64.const 1)))))))

  (func (export "store") (param $addr i32) (param $value i32)
    (i32.store (local.get $addr) (local.get $value)))

  (data (i32.const 0) "hello")
)
