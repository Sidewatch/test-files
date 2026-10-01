;; Clojure 1.12 — syntax showcase
;; Warehouse inventory in Clojure.
;; Semicolons start line comments; #_ discards the next form.
;; TODO: persist the stock map to a database.
#!/usr/bin/env clojure
#_(println "this form is discarded by the reader")

(ns sample.inventory
  "Stock levels, reorder suggestions and reports."
  (:refer-clojure :exclude [update])
  (:require [clojure.string :as str]
            [clojure.set :as set :refer [union intersection]]
            [clojure.java.io :as io]
            [clojure.walk :refer :all]
            [clojure.core.async :as async :refer [go chan <! >!]])
  (:import (java.util Date UUID)
           (java.time LocalDate Instant)
           java.io.File)
  (:gen-class))

(set! *warn-on-reflection* true)

;; ── Literals ────────────────────────────────────────────────────────
nil
true
false
42                    ; long
-17
0xFF                  ; hex
0777                  ; octal
2r1010                ; radix
36rZZ
3.14
-0.5
1e10
1.5E-3
42N                   ; BigInt
3.14M                 ; BigDecimal
22/7                  ; ratio
##Inf
##-Inf
##NaN
\a \newline \space \tab é \o101     ; characters
"A string with \"escapes\", \t tab, \n newline, \\ backslash and é."
"Multi-line
string literal"
#"^[A-Z]-\d{3}$"      ; regex
:keyword
:ns/qualified
::auto-resolved
::alias/resolved
'quoted-symbol
sym/qualified

;; ── Collections ─────────────────────────────────────────────────────
[1 2 3 4]
'(1 2 3)
#{:a :b :c}
{:sku "A-100" :qty 12 :price 4.5}
{:nested {:deeper [1 2 {:x 1}]}}
#:warehouse{:id 1 :name "Central"}
#::{:auto 1}
#inst "2024-01-01T00:00:00.000-00:00"
#uuid "00000000-0000-0000-0000-000000000000"
#?(:clj :jvm :cljs :js :default :other)

;; ── Definitions ─────────────────────────────────────────────────────
(def ^:const reorder-point 25)
(def ^:private ^:dynamic *verbose* false)
(def ^{:doc "Tax rate"} tax-rate 0.2)
(defonce registry (atom {}))
(def ^String greeting "Hello")

(defrecord Item [sku qty price])
(deftype Shelf [^long id ^:volatile-mutable items])

(defprotocol Summary
  "Things that can summarise themselves."
  (summarise [this] "Return a string."))

(extend-protocol Summary
  Item
  (summarise [{:keys [sku qty]}] (str sku ": " qty))
  nil
  (summarise [_] "nothing"))

(defmulti classify :category)
(defmethod classify :tools [_] :hardware)
(defmethod classify :default [_] :other)

(definterface Stockable
  (^long getQty [])
  (setQty [^long q]))

;; ── Functions ───────────────────────────────────────────────────────
(defn low-stock
  "Items whose quantity is below the reorder point."
  [items]
  (filter #(< (:qty %) reorder-point) items))

(defn total-value
  ([items] (total-value items 1.0))
  ([items factor]
   (* factor (reduce + (map (fn [{:keys [qty price]}] (* qty price)) items)))))

(defn- private-helper [x & more]
  (apply + x more))

(defn describe
  [{:keys [sku qty] :or {qty 0} :as item} & {:keys [verbose] :or {verbose false}}]
  (str sku " has " qty (when verbose (str " in " item))))

(defn destructure-demo [[a b & rest :as all] {:strs [x] :syms [y] :keys [z]}]
  [a b rest all x y z])

;; ── Macros ──────────────────────────────────────────────────────────
(defmacro unless [test & body]
  `(if (not ~test) (do ~@body)))

(defmacro with-timing [label & body]
  `(let [start# (System/nanoTime)
         result# (do ~@body)]
     (println ~label (- (System/nanoTime) start#) "ns")
     result#))

;; ── Special forms and control flow ──────────────────────────────────
(defn flow [x]
  (cond
    (neg? x) :negative
    (zero? x) :zero
    :else :positive))

(defn flow2 [x]
  (case x
    1 :one
    (2 3) :few
    :many))

(defn flow3 [x]
  (if-let [v (get {:a 1} x)]
    (when-let [w (inc v)] w)
    (if-not x 0 1)))

(defn loops []
  (loop [i 0 acc []]
    (if (< i 3)
      (recur (inc i) (conj acc i))
      acc))
  (doseq [x (range 3) :when (odd? x)] (println x))
  (dotimes [n 3] (println n))
  (for [x (range 3) y (range 3) :when (not= x y)] [x y])
  (while false nil))

(defn errors []
  (try
    (throw (ex-info "boom" {:code 42}))
    (catch clojure.lang.ExceptionInfo e (ex-data e))
    (catch Exception e (.getMessage e))
    (finally (println "cleanup"))))

;; ── Threading, anonymous functions, reader conditionals ─────────────
(->> (range 10) (filter even?) (map #(* % %)) (reduce +))
(-> {:a 1} (assoc :b 2) (update :a inc) (dissoc :b))
(some-> {:a {:b 1}} :a :b)
(as-> 5 $ (+ $ 1) (* $ 2))
(cond-> {} true (assoc :x 1) false (assoc :y 2))
(#(+ %1 %2 %&) 1 2 3)
(map (fn named [x] (* x 2)) [1 2 3])
(comp inc inc)
(partial + 1)
((juxt :a :b) {:a 1 :b 2})

;; ── Java interop ────────────────────────────────────────────────────
(.toUpperCase "abc")
(. "abc" toUpperCase)
(String/valueOf 42)
(Math/PI)
Math/E
(new java.util.Date)
(java.util.Date.)
(doto (java.util.ArrayList.) (.add 1) (.add 2))
(set! (.-field obj) 1)
(proxy [Object] [] (toString [] "proxied"))
(reify Summary (summarise [_] "reified"))
(memfn toString)
^long (+ 1 2)
(type ^bytes (byte-array 3))

;; ── State: atoms, refs, agents, delays, futures ─────────────────────
(def stock (atom {:A-100 12}))
(swap! stock update :A-100 + 5)
(reset! stock {})
@stock
(deref stock)
(def r (ref 0))
(dosync (alter r inc) (ref-set r 10))
(def a (agent 0))
(send a inc)
(def d (delay (println "once") 42))
(force d)
(def f (future (Thread/sleep 10) :done))
(def p (promise))
(deliver p 1)
(binding [*verbose* true] (println *verbose*))
(with-redefs [low-stock identity] (low-stock []))
(locking registry (swap! registry assoc :x 1))
(lazy-seq (cons 1 nil))
(sorted-map :b 2 :a 1)
(meta #'low-stock)
(var low-stock)
#'low-stock

;; ── Main ────────────────────────────────────────────────────────────
(defn -main [& args]
  (let [items [(->Item "A-100" 12 4.5) (->Item "B-200" 40 1.25) (->Item "C-300" 3 99.0)]
        low   (low-stock items)]
    (unless (empty? low)
      (println "Reorder:" (str/join ", " (map :sku low))))
    (printf "Stock value: %.2f%n" (total-value items))
    (comment (println "rich comment form"))
    (with-timing "report" (doall (map summarise items)))))

;; ── Further constructs ──────────────────────────────────────────────
;; Namespaced maps, tagged literals, metadata variations
^{:author "team" :doc "metadata map"} {:with :meta}
^:dynamic ^:private x-meta 1
^String ^:tag type-hinted-form
#^{:legacy "metadata syntax"} legacy-meta
(def ^{:arglists '([x])} documented (fn [x] x))
(def ^:deprecated old-name 1)

;; Numeric tower and character oddities
[0x7FFFFFFF 0X1f 01 -0x10 2r-101 16rFF 1e0 1.E2 +1 -1.5e+3 1N 0N -1N 1M 1.0M 1/2 -1/2 ##Inf ##-Inf ##NaN]
[\a \A \0 \space \newline \return \tab \backspace \formfeed \u0041 \u00E9 \o7 \o101 \( \) \" \\ \;]
["" "\u00e9" "\\" "\"" "tab\tnewline\nreturn\rbackspace\bformfeed\f" "octal\101" "unicode \uD83D\uDE00"]
[#"" #"\\d+" #"(?i)case" #"a|b" #"[\]\[]" #"\"quoted\""]

;; Keywords and symbols in odd forms
[:a :a/b ::a ::x/a :a.b/c :+ :- :* :/ :? :! :<= :>= :=> :_ :a-b_c? :1 :a:b]
['a 'a/b 'a.b.c 'a.b/c '+ '- '* '/ '? '! '<= '>= '=> '_ '->x '->> 'a? 'a! 'a* 'a' '.a 'a. 'nil? '& '& 'ns.name/sym]
['java.lang.String 'String/valueOf 'Math/PI 'Integer/MAX_VALUE '.method '.-field 'Class. '->Record 'map->Record]

;; Reader macros
'quoted
`(syntax-quoted ~unquoted ~@spliced auto-gensym# ns/qualified)
@deref-me
#'var-quote
#(inc %)
#(+ %1 %2 %3)
#(apply + %&)
#{1 2 3}
#_discarded
#_#_discard-two forms
#_ (discarded form)
#?@(:clj [1 2] :cljs [3 4])
#?(:clj (clojure.core/inc 1) :cljs (js/parseInt "1") :cljr 1)
#:ns{:a 1 :b {:c 2}}
#::{:auto 1}
#::alias{:aliased 1}
#js {:a 1}
#js [1 2 3]
#object[java.lang.Object 0x1 "obj"]
#my/tag {:custom true}
#=(+ 1 2)
#<unreadable>

;; Special forms, macros and core in the breadth
(ns sample.extras
  (:refer-clojure :only [defn let])
  (:use [clojure.pprint :only [pprint]])
  (:require [clojure.edn :as edn] [clojure.test :refer [deftest is testing are run-tests]]
            [clojure.spec.alpha :as s] [clojure.data :as data])
  (:import [java.util.concurrent ConcurrentHashMap TimeUnit]
           (java.io BufferedReader InputStreamReader))
  (:load "extras/more")
  (:gen-class :name sample.Main :main true :extends java.lang.Object :implements [java.lang.Runnable]
              :methods [[run [] void]] :state state :init init :constructors {[] []}))

(import 'java.util.Date)
(require 'clojure.string)
(use 'clojure.set)
(refer 'clojure.string :only '[join])
(alias 'str 'clojure.string)
(in-ns 'sample.other)
(create-ns 'sample.dynamic)
(load-file "other.clj")
(declare forward-ref)
(defn- priv [] forward-ref)
(def forward-ref 1)
(defmacro my-when [t & b] (list 'if t (cons 'do b)))
(definline sq [x] `(* ~x ~x))
(defmulti area (fn [s] (:shape s)) :default :unknown :hierarchy #'h)
(defmethod area :circle [{:keys [r]}] (* Math/PI r r))
(defmethod area :default [_] 0)
(prefer-method area :a :b)
(derive ::child ::parent)
(isa? ::child ::parent)
(def h (make-hierarchy))
(defstruct person :name :age)
(def p (struct person "Ann" 30))
(create-struct :a :b)
(defrecord Pt [x y] Object (toString [_] (str x "," y)) clojure.lang.IFn (invoke [_] x))
(deftype Mutable [^:unsynchronized-mutable n] clojure.lang.IDeref (deref [_] n))
(extend-type String Summary (summarise [s] s))
(extend Pt Summary {:summarise (fn [p] (str p))})
(satisfies? Summary "x")
(reify Runnable (run [_] (println "running")))
(proxy [Thread] [] (run [] (println "proxied")))
(gen-class :name sample.Gen)
(gen-interface :name sample.Iface :methods [[go [] void]])
(letfn [(even?* [n] (if (zero? n) true (odd?* (dec n)))) (odd?* [n] (if (zero? n) false (even?* (dec n))))] (even?* 10))
(binding [*out* *err*] (println "to stderr"))
(with-open [r (io/reader "file.txt")] (doall (line-seq r)))
(with-out-str (print "captured"))
(with-meta [1 2] {:m 1})
(vary-meta [1] assoc :k 2)
(set-validator! (atom 0) pos?)
(add-watch (atom 0) :k (fn [k r o n] (println k o n)))
(alter-var-root #'x-meta inc)
(intern 'sample.extras 'dyn 42)
(ns-resolve *ns* 'priv)
(resolve 'inc)
(eval '(+ 1 2))
(read-string "{:a 1}")
(macroexpand-1 '(my-when true 1))
(clojure.walk/postwalk identity [1 2])
(trampoline (fn f [n] (if (zero? n) :done #(f (dec n)))) 10)
(lazy-cat [1] [2])
(iterate inc 0)
(cycle [1 2])
(repeatedly rand)
(partition-by odd? [1 3 2 4])
(group-by even? (range 10))
(frequencies "hello")
(reduce-kv (fn [m k v] (assoc m v k)) {} {:a 1})
(transduce (comp (map inc) (filter even?)) + 0 (range 10))
(into [] (comp (take 3) (map str)) (range))
(sequence (map inc) [1 2 3])
(completing +)
(volatile! 0)
(reduced 1)
(unreduced (reduced 1))
(tap> {:event :stock})
(add-tap println)
(try (throw (Exception. "x")) (catch Exception e (throw e)) (finally nil))
(monitor-enter o) (monitor-exit o)
(set! *warn-on-reflection* true)
(assert (pos? 1) "must be positive")
(s/def ::sku (s/and string? #(re-matches #"[A-Z]-\d+" %)))
(s/fdef low-stock :args (s/cat :items coll?) :ret seq?)
(deftest low-stock-test
  (testing "finds low items"
    (is (= 1 (count (low-stock [{:qty 1}]))))
    (are [x y] (= x y) 1 1 2 2)))
(comment
  (run-tests)
  (pprint (data/diff {:a 1} {:a 2})))
;; TODO: replace with a transducer pipeline.

;; ── Clojure 1.11 and 1.12 additions ─────────────────────────────────
(ns sample.modern
  (:require [clojure.string :as-alias str-alias]   ; alias without loading
            [clojure.repl.deps :refer [add-lib add-libs sync-deps]]
            [clojure.java.basis :as basis]))

;; Param-tags metadata and qualified methods (1.12)
(map String/.length ["a" "bb" "ccc"])
(map String/valueOf [1 2 3])
(mapv Integer/parseInt ["1" "2"])
(String/new "from constructor reference")
(map Integer/new [1 2])
(defn parse ^[String] [s] (Integer/parseInt s))
(def length-fn ^[String] String/.length)
(def indexed-of ^{:param-tags [String long]} String/.charAt)
(^[long long] Math/max 1 2)
(^[_ long] String/.substring "hello" 2)

;; Array class syntax (1.12)
(def longs-class long/1)
(def strings-class String/1)
(def matrix-class double/2)
(into-array String/1 [["a"] ["b"]])
(aget (make-array long/2 2 2) 0 0)

;; Functional interface conversion (1.12)
(let [^java.util.function.Function f inc
      ^java.util.function.Predicate p even?]
  [(.apply f 1) (.test p 2)])
(.forEach [1 2 3] println)
(java.util.concurrent.CompletableFuture/supplyAsync (fn [] 42))
(Thread/ofVirtual)
(-> (Thread/ofVirtual) (.start (fn [] (println "virtual thread"))))

;; New core functions (1.11 and 1.12)
(parse-long "42")
(parse-double "3.14")
(parse-uuid "00000000-0000-0000-0000-000000000000")
(parse-boolean "true")
(random-uuid)
(abs -5)
(NaN? ##NaN)
(infinite? ##Inf)
(update-keys {:a 1 :b 2} name)
(update-vals {:a 1 :b 2} inc)
(iteration (fn [k] {:next (when (< k 3) (inc k)) :v k}) :vf :v :kf :next :initk 0)
(partitionv 3 (range 10))
(partitionv-all 3 (range 10))
(splitv-at 2 [1 2 3 4])
(stream-reduce! + 0 (java.util.stream.Stream/of 1 2 3))
(stream-into! [] (java.util.stream.Stream/of 1 2 3))
(stream-seq! (java.util.stream.Stream/of 1 2 3))
(stream-transduce! (map inc) + 0 (java.util.stream.Stream/of 1 2 3))
(requiring-resolve 'clojure.string/join)
(add-lib 'org.clojure/data.json)
(basis/initial-basis)

;; More binding and conditional forms
(if-some [v (get {:a nil} :a)] v :absent)
(when-some [v (get {:a 1} :a)] (inc v))
(when-first [x [1 2 3]] x)
(cond->> [1 2 3] true (map inc) false (filter even?))
(condp = 2 1 :one 2 :two :other)
(condp contains? #{1 2} 1 :found :missing)
(case 'sym sym :symbol "str" :string :default)
(let [{:keys [a b] :or {b 2} :as m} {:a 1}
      {:keys [x/y] :as ns-map} {:x/y 1}
      {:person/keys [name age]} {:person/name "Ann" :person/age 30}
      [p q & more] (range 5)
      {[r s] :pair} {:pair [1 2]}]
  [a b m y name age p q more r s])

;; Records, protocols and multimethods in newer forms
(defrecord Order [id sku qty]
  Summary
  (summarise [this] (str "Order " id)))
(->Order 1 "A-100" 5)
(map->Order {:id 1 :sku "A-100" :qty 5})
(defprotocol Repo
  (find-one [this id])
  (find-all [this] [this opts]))
(defmulti handle (juxt :type :version))
(defmethod handle [:order 1] [m] :order-v1)
(defmethod handle [:order 2] [m] :order-v2)
(defmethod handle :default [m] :unknown)

;; Transients, volatile state and concurrency helpers
(persistent! (reduce conj! (transient []) (range 5)))
(let [v (volatile! 0)] (vswap! v inc) @v)
(def pool (java.util.concurrent.Executors/newFixedThreadPool 2))
(pmap inc (range 10))
(pcalls #(1) #(2))
(pvalues (+ 1 1) (+ 2 2))
(let [c (chan 10)] (async/>!! c 1) (async/<!! c))
(async/go-loop [i 0] (when (< i 3) (async/<! (async/timeout 1)) (recur (inc i))))
(async/alts!! [(async/timeout 10)])

;; Metadata, reader conditionals and tagged literals in one place
^{:added "1.12" :see-also ["other"]} (defn tagged-fn [] 1)
#?(:clj  (defn platform [] :jvm)
   :cljs (defn platform [] :js)
   :cljr (defn platform [] :clr))
[1 #?@(:clj [2 3] :cljs [4]) 5]
#inst "2025-06-15T12:00:00.000-00:00"
#uuid "11111111-1111-1111-1111-111111111111"
(def tagged {:when #inst "2025-06-15" :id #uuid "11111111-1111-1111-1111-111111111111"})
