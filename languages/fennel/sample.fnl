#!/usr/bin/env fennel
;; ── Comments ──
;; Line comment. TODO: persist bins. FIXME: handle negative stock.
;;; Section comment
; single semicolon comment

;; ── Requires and modules ──
(local fennel (require :fennel))
(local {: view : dofile} fennel)
(local json (require :cjson))
(import-macros {: assert-eq} :test-macros)
(require-macros :warehouse-macros)
(include :vendored.helpers)

;; ── Literals ──
(local numbers [42 -17 1_000_000 0xFF 0x1.8p1 3.14 -2.5 6.02e23 1.5e-10 (/ 1 0) (/ -1 0) (/ 0 0)])
(local booleans [true false])
(local nothing nil)
(local strings ["plain" "Warehouse \"north\"\t\n" "unicode \u{E9} \u{1F4E6}" "hex \x41 dec \065" "line
break"])
(local keywords [:warehouse :north-bin :a.b :with_underscore])
(local sequence [1 2 3 "four" :five])
(local table {:sku "A-100" :qty 12 :price 4.5 :tags [:steel :tool]})
(local mixed {1 "one" 2 "two" :three 3 "key with space" true})
(local nested {:a {:b {:c [1 {:d "deep"}]}}})
(local shorthand-name :north)
(local shorthand {: shorthand-name})
(local vararg-count (select "#" 1 2 3))
(local char-code (string.byte "A"))
(local multi-sym table.field.sub)
(local method-call (: "hello" :upper))
(local method-sugar (("hello"):upper))
(local empty-table {})
(local empty-seq [])

;; ── Variables ──
(var counter 0)
(set counter (+ counter 1))
(local (a b) (values 1 2))
(local [first second & rest] [1 2 3 4 5])
(local {:sku sku :qty qty} {:sku "A-100" :qty 12})
(local {: price : tags} table)
(global warehouse-name "north")
(set-forcibly! counter 10)
(let [x 1 y 2
      [p q] [3 4]
      {: sku} {:sku "B-200"}]
  (+ x y p q))

;; ── Functions ──
(fn clamp [value lo hi]
  "Clamp VALUE between LO and HI."
  (math.max lo (math.min hi value)))

(fn greet [name ?greeting]
  (.. (or ?greeting "Hello") ", " name "!"))

(fn variadic [first ...]
  (let [rest [...]]
    (+ first (length rest))))

(fn destructure [{: sku : qty} [a b]]
  (print sku qty a b))

(local double (fn [x] (* x 2)))
(local square #(* $1 $1))
(local sum-all #(+ $...))
(local lambda-fn (lambda [x ?y] (+ x (or ?y 0))))
(local λ-fn (λ [x] x))
(local partial-add (partial + 1))
(local composed (-> 5 (+ 1) (* 2)))
(local composed-last (->> [1 2 3] (icollect [_ v (ipairs $)] (* v 2))))

(fn make-light [initial]
  (var state (or initial :red))
  (var elapsed 0)
  {:tick (fn [seconds]
           (set elapsed (+ elapsed seconds))
           (when (>= elapsed 30)
             (set state :green)
             (set elapsed 0))
           state)
   :state (fn [] state)})

;; ── Control flow ──
(fn control [items mode]
  (if (> (length items) 3)
      :many
      (= mode :fast)
      :quick
      :few)
  (when (not= mode :slow) (print "not slow"))
  (when-not (= mode :fast) (print "unless"))
  (match mode
    :fast :quick
    [a b] (+ a b)
    {: sku} sku
    (where n (> n 3)) :big
    (or :a :b) :ab
    nil :none
    _ :other)
  (match-try (values 1 2)
    (1 x) (+ x 1)
    (catch _ :fail))
  (each [k v (pairs {:a 1 :b 2})] (print k v))
  (each [i v (ipairs items)] (print i v))
  (for [i 1 10] (print i))
  (for [i 10 1 -2] (print i))
  (var n 0)
  (while (< n 3)
    (set n (+ n 1))
    (when (= n 2) (lua :break)))
  (icollect [_ v (ipairs items)] (when (> v 0) v))
  (collect [k v (pairs {:a 1})] (values k (* v 2)))
  (accumulate [sum 0 _ v (ipairs items)] (+ sum v))
  (faccumulate [sum 0 i 1 10] (+ sum i))
  (fcollect [i 1 5] (* i i))
  (do (print "block") 42)
  (pcall error "boom")
  (xpcall (fn [] (error "bad")) (fn [msg] (print msg)))
  (error "stock error" 2)
  (assert (> n 0) "n must be positive")
  (goto done)
  (lua "-- raw lua")
  ::done::)

;; ── Operators ──
(local ops [(+ 1 2 3) (- 5) (- 5 3) (* 2 3) (/ 9 2) (// 9 2) (% 9 2) (^ 2 8)
            (= 1 1) (not= 1 2) (< 1 2) (<= 1 2) (> 2 1) (>= 2 1)
            (and true false) (or false true) (not true)
            (.. "a" "b" "c") (length [1 2 3]) (# [1 2 3])
            (band 5 3) (bor 5 3) (bxor 5 3) (bnot 5) (lshift 1 4) (rshift 16 2)
            (. table :sku) (?. table :missing :deeper) (. [10 20 30] 2)])

;; ── Macros ──
(macro unless2 [cond ...]
  `(when (not ,cond) ,...))

(macros {:inc (fn [x] `(+ ,x 1))
         :debug (fn [expr] `(print ,(view expr) ,expr))})

(eval-compiler
  (set _G.compiled-at (os.time)))

(comment
  (print "ignored form"))

;; ── Further constructs ──
;; Metadata, attributes, and function forms
(fn ^:fnl/arglist documented [a b] "Doc string" (+ a b))
(fn named-args [{: sku &as whole}] whole)
(fn tail-call [n acc] (if (= n 0) acc (tail-call (- n 1) (+ acc n))))
(lambda strict [x ?opt] (+ x (or ?opt 0)))
(local <const> frozen 42)
(local <close> handle (io.open "/dev/null"))
(with-open [f (io.open "/dev/null")] (f:read "*a"))
(doto (io.stdout) (: :write "chained ") (: :flush))
(hashfn (+ $1 $2))
(pick-values 2 (values 1 2 3))
(table.unpack [1 2 3])
(select :# 1 2 3)
(tset {} :k "v")
(let [t {}] (tset t :nested {}) (tset t.nested :deep 1) t.nested.deep)
(. {:a {:b 1}} :a :b)
(?. {:a nil} :a :b)
(print (.. "a" 1 2.5 :kw))
(local {:a a-val :b {:c c-val}} {:a 1 :b {:c 2}})
(local [x1 [x2 x3] & tail] [1 [2 3] 4 5])
(global *globals* {})

;; Strings and numbers of every shape
(local literals
  [0 -1 +1 123 0xff 0XFF 1e3 1E-3 1.5e+3 .5 5. 3.14159 1_000_000 (/ 1 0) (- (/ 1 0))
   "" "double \"quotes\"" "tab\t nl\n cr\r bell\a bs\b ff\f vt\v bslash\\ quote\' dquote\""
   "decimal \065 hex \x41 unicode \u{41} \u{1F4E6} skip \z
      whitespace"
   :keyword :kw-with-dash :kw.with.dots :kw_under :kw123 :+ :- :* :/ :=
   "multi
line string"])

;; Quoting and macros
(macro swap! [a b] `(let [tmp# ,a] (set ,a ,b) (set ,b tmp#)))
(macro my-when [cond ...] (list 'if cond (list 'do ...)))
(macro with-gensym [] (let [g (gensym :tmp)] `(let [,g 1] ,g)))
(macro exports [] {:a 1 :b 2})
(macros {:twice (fn [x] `(do ,x ,x))})
(eval-compiler (print "compile-time") (set _G.during-compile true))
(local quoted-forms [`(a b ,c) `(list ,(unpack [1 2])) '(plain list) `[vector ,x] `{:table ,y}])

;; Operators in function position
(+ 1 2) (- 1 2) (* 1 2) (/ 1 2) (// 7 2) (% 7 2) (^ 2 3)
(= 1 1) (not= 1 2) (< 1 2) (> 2 1) (<= 1 1) (>= 1 1)
(and 1 2) (or nil 2) (not nil)
(.. "a" "b") (# "abc") (: "abc" :upper) (: "abc" :sub 1 2)
(band 1 3) (bor 1 2) (bxor 1 3) (bnot 0) (lshift 1 2) (rshift 8 2)
(math.floor 3.7) (math.max 1 2) (string.format "%5.2f|%-5s|%d|%x|%q" 1.5 "a" 3 255 "q")
(string.gsub "a b" "%s" "_") (string.match "A-100" "^(%a)-(%d+)$") (string.rep "ab" 3)
(table.insert [] 1) (table.concat ["a" "b"] ",") (table.sort [3 1 2] #(< $1 $2)) (table.remove [1 2] 1)
(os.time) (os.date "%Y-%m-%d") (os.getenv "HOME") (io.write "x") (io.read :l)
(tostring 1) (tonumber "42") (type {}) (rawget {} :k) (rawset {} :k 1) (setmetatable {} {:__index {}}) (getmetatable {})
(assert true "message") (collectgarbage :count)
(coroutine.wrap (fn [] (coroutine.yield 1)))
(let [co (coroutine.create (fn [a] (coroutine.yield a)))] (coroutine.resume co 1))
(match [1 2 3]
  [a b & rest] (+ a b)
  {:x x :y y} (+ x y)
  (where [n] (> n 1)) n
  (or [1] [2]) :one-or-two
  [a &as whole] whole
  ?x ?x
  "literal" :string
  :keyword :kw
  nil :nothing
  true :yes
  _ :default)
(case 5 5 :five _ :other)
(case-try (pcall error :x) (true v) v (catch (false e) e))
(fennel.eval "(+ 1 2)" {:env _G})

;; ── Module return ──
(local M {: clamp : greet : make-light})
(print (greet "warehouse") (view (make-light :green)))
M
