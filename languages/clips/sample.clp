;;; CLIPS 6.4.2 — syntax showcase
;;; CLIPS expert system: warehouse reorder advisor.
;;; Semicolons start comments that run to the end of the line.
;;; TODO: load the thresholds from a file.

; ── Constructs: templates ───────────────────────────────────────────
(deftemplate item
   "A stocked item."
   (slot sku (type SYMBOL))
   (slot name (type STRING) (default "unnamed"))
   (slot qty (type INTEGER) (range 0 ?VARIABLE) (default 0))
   (slot price (type FLOAT) (default 0.0))
   (slot category (type SYMBOL) (allowed-symbols tools parts fasteners) (default tools))
   (multislot tags (type SYMBOL))
   (slot supplier (default ?NONE)))

(deftemplate reorder
   (slot sku)
   (slot amount (type INTEGER))
   (slot urgent (allowed-values yes no) (default no)))

(deftemplate symptom (slot name) (slot severity (type INTEGER) (default 1)))

; ── Globals and constants ───────────────────────────────────────────
(defglobal
   ?*threshold* = 25
   ?*max-order* = 1000
   ?*tax-rate* = 0.2
   ?*greeting* = "Warehouse advisor"
   ?*scientific* = 1.5e-3
   ?*negative* = -42)

; ── Facts ───────────────────────────────────────────────────────────
(deffacts initial-stock
   "Initial inventory."
   (item (sku A-100) (name "Widget") (qty 12) (price 4.5) (tags fragile blue) (supplier acme))
   (item (sku B-200) (name "Gadget") (qty 40) (price 1.25) (supplier globex))
   (item (sku C-300) (name "Gizmo") (qty 3) (price 99.0) (category parts) (supplier acme))
   (day monday)
   (counter 0)
   (list a b c 1 2.5 "string" (nested fact)))

; ── Functions ───────────────────────────────────────────────────────
(deffunction average (?a ?b)
   (/ (+ ?a ?b) 2))

(deffunction value-of (?qty ?price)
   (return (* ?qty ?price)))

(deffunction describe-level ($?args)
   (bind ?n (length$ ?args))
   (if (> ?n 3) then
      (return high)
    else
      (if (> ?n 0) then (return low) else (return none))))

(deffunction countdown (?n)
   (while (> ?n 0) do
      (printout t ?n " ")
      (bind ?n (- ?n 1)))
   (printout t crlf))

(deffunction loop-demo ()
   (loop-for-count (?i 1 3) do
      (printout t "i = " ?i crlf))
   (foreach ?x (create$ a b c)
      (printout t ?x crlf))
   (switch ?*threshold*
      (case 25 then (printout t "default" crlf))
      (case 50 then (printout t "high" crlf))
      (default (printout t "custom" crlf))))

; ── Rules ───────────────────────────────────────────────────────────
(defrule low-stock
   "Flag items below the threshold."
   (declare (salience 10) (auto-focus FALSE))
   ?i <- (item (sku ?s) (qty ?q&:(< ?q ?*threshold*)) (name ?n))
   (not (reorder (sku ?s)))
   =>
   (assert (reorder (sku ?s) (amount (- ?*threshold* ?q)) (urgent (if (< ?q 5) then yes else no))))
   (printout t "Low stock: " ?n " (" ?s ") qty=" ?q crlf))

(defrule urgent-reorder
   (declare (salience 100))
   ?r <- (reorder (sku ?s) (urgent yes) (amount ?a))
   (item (sku ?s) (supplier ?sup))
   =>
   (printout t "URGENT: order " ?a " of " ?s " from " ?sup crlf)
   (retract ?r))

(defrule expensive-or-fragile
   (or (item (sku ?s) (price ?p&:(> ?p 50)))
       (item (sku ?s) (tags $? fragile $?)))
   (not (and (item (sku ?s) (qty ?q&~0&:(> ?q 100))) (test (> ?q 200))))
   (exists (item (category parts)))
   (forall (item (sku ?x)) (item (sku ?x) (qty ?)))
   (logical (day ?d&monday|tuesday))
   (test (neq ?s none))
   =>
   (bind ?msg (str-cat "Check " ?s))
   (printout t ?msg crlf)
   (modify 1 (qty 0))
   (duplicate 1 (sku D-400)))

(defrule flu-suspected
   (symptom (name fever) (severity ?s&:(> ?s 2)))
   (symptom (name cough))
   =>
   (assert (diagnosis (condition flu) (confidence 0.75)))
   (printout t "Flu suspected (fever severity " ?s ")" crlf))

(defrule report
   (diagnosis (condition ?c) (confidence ?p))
   =>
   (printout t "Diagnosis: " ?c " at " (* ?p 100) "%" crlf))

(defrule with-multifield
   (list $?before c $?after)
   (list ? ?second $?)
   (object (is-a PERSON) (name ?name))
   =>
   (printout t ?before ?after ?second crlf))

; ── Modules ─────────────────────────────────────────────────────────
(defmodule MAIN (export ?ALL))
(defmodule REPORTS (import MAIN ?ALL) (export deftemplate report-line))

(defrule REPORTS::summarise
   =>
   (focus MAIN)
   (return))

; ── Classes and messages (COOL) ─────────────────────────────────────
(defclass PERSON
   (is-a USER)
   (role concrete)
   (slot name (create-accessor read-write))
   (slot age (type INTEGER) (default 0))
   (multislot roles))

(defmessage-handler PERSON greet ()
   (printout t "Hi, " ?self:name crlf))

(definstances people
   (alice of PERSON (name "Alice") (age 30)))

(defgeneric describe)
(defmethod describe ((?x INTEGER)) (printout t "int " ?x crlf))
(defmethod describe ((?x STRING)) (printout t "string " ?x crlf))

; ── Expressions and built-ins ───────────────────────────────────────
(bind ?x (+ 1 (* 2 3) (- 10 4) (/ 9 3) (mod 7 3) (** 2 8)))
(bind ?s (str-cat "a" "b" (sym-cat c d) (upcase "x")))
(bind ?m (create$ 1 2 3 (nth$ 2 (create$ a b))))
(bind ?r (and (> ?x 1) (or (< ?x 100) (not (= ?x 5))) (eq a a) (neq a b) (<> 1 2) (>= 3 2) (<= 2 3)))
(printout t "x=" ?x " s=" ?s crlf)
(assert (counter (+ 1 1)))
(retract 1)
(run)
(reset)
(clear)
(load "other.clp")
(batch "script.bat")
(agenda)
(facts)
(rules)
(watch rules)
(unwatch all)
(exit)

; ── Further constructs ──────────────────────────────────────────────
; Slot constraints and facets, in full
(deftemplate constrained
   (slot a (type INTEGER FLOAT NUMBER SYMBOL STRING LEXEME INSTANCE-NAME INSTANCE-ADDRESS INSTANCE EXTERNAL-ADDRESS FACT-ADDRESS))
   (slot b (allowed-symbols red green) (allowed-strings "x" "y") (allowed-integers 1 2 3) (allowed-floats 1.0 2.0) (allowed-numbers 1 2.5) (allowed-lexemes a "b") (allowed-instance-names [i1]) (allowed-classes PERSON))
   (slot c (range 0 100) (range ?VARIABLE 10) (range 5 ?VARIABLE))
   (multislot d (cardinality 1 5) (cardinality 0 ?VARIABLE))
   (slot e (default-dynamic (gensym*)))
   (slot f (default ?DERIVE))
   (multislot g (default a b c)))

; Pattern-matching constraints
(defrule constraint-forms
   (declare (salience (+ 1 2)) (auto-focus TRUE) (no-loop TRUE))
   ?f1 <- (constrained (a ?x) (b red|green) (c ~5) (d $?rest) (e ?y&~nil&:(numberp ?y)) (f =(+ 1 2)))
   (constrained (a ?x&~0) (b ~red&~green))
   (constrained (a ?) (b $?))
   (not (constrained (a 99)))
   (test (and (> ?x 0) (<= ?x 10) (or (eq ?x 1) (neq ?x 2))))
   (object (is-a PERSON) (name ?n&:(stringp ?n)) (age ?a&:(> ?a 18)))
   ?i <- (object (is-a PERSON) (name "Alice"))
   (initial-fact)
   =>
   (retract ?f1)
   (modify ?f1 (a 3) (d 1 2 3))
   (assert (constrained (a ?x)))
   (halt))

; Control and iteration functions
(deffunction control-demo (?n $?rest)
   (bind ?i 0)
   (while (< ?i ?n) do (bind ?i (+ ?i 1)))
   (loop-for-count (?j 0 ?n) (printout t ?j " "))
   (loop-for-count 3 (printout t "."))
   (progn$ (?item ?rest) (printout t ?item crlf))
   (foreach ?e (create$ 1 2 3) (printout t ?e))
   (if (> ?n 0) then (printout t "pos") elif (< ?n 0) then (printout t "neg") else (printout t "zero"))
   (switch ?n (case 0 then (return 0)) (case 1 then (return 1)) (default (return -1)))
   (break)
   (return))

; Built-ins by family
(deffunction builtins ()
   (bind ?m (create$ a b c d))
   (bind ?x (+ (nth$ 1 ?m) (length$ ?m)))
   (subseq$ ?m 2 3)
   (first$ ?m) (rest$ ?m) (delete$ ?m 1 1) (insert$ ?m 2 z) (replace$ ?m 1 1 q)
   (member$ b ?m) (subsetp (create$ a) ?m) (union$ ?m ?m) (intersection$ ?m ?m) (complement$ ?m ?m)
   (explode$ "a b c") (implode$ ?m)
   (str-cat "a" "b") (sym-cat a b) (str-length "abc") (str-index "b" "abc") (sub-string 1 2 "abc")
   (str-compare "a" "b") (upcase "x") (lowcase "X") (string-to-field "42") (eval "(+ 1 2)") (build "(defrule r =>)")
   (abs -1) (min 1 2) (max 1 2) (div 7 2) (mod 7 2) (sqrt 16) (exp 1) (log 10) (round 1.5) (integer 1.5) (float 1)
   (sin 0) (cos 0) (tan 0) (asin 0) (acos 1) (atan 0) (pi) (deg-rad 180) (rad-deg 3.14) (** 2 3)
   (random) (random 1 10) (seed 42) (time) (gensym) (gensym*) (setgen 1)
   (integerp 1) (floatp 1.0) (numberp 1) (symbolp a) (stringp "s") (lexemep a) (multifieldp ?m) (evenp 2) (oddp 1) (pointerp 1)
   (eq 1 1) (neq 1 2) (= 1 1) (<> 1 2) (< 1 2) (> 2 1) (<= 1 1) (>= 1 1) (not FALSE) (and TRUE TRUE) (or FALSE TRUE)
   (fact-index 1) (fact-slot-value 1 a) (get-fact-list) (assert-string "(foo bar)")
   (open "file.txt" myfile "w") (printout myfile "x" crlf) (close myfile) (read) (readline) (format t "%5.2f %s %d~n" 3.14 "s" 7)
   (rename "a" "b") (remove "x") (system "ls") (dribble-on "log.txt") (dribble-off)
   (get-focus) (get-focus-stack) (pop-focus) (list-focus-stack) (set-strategy depth) (get-strategy) (set-salience-evaluation when-activated)
   (undefrule low-stock) (ppdefrule report) (list-defrules) (matches report) (refresh report) (set-break report) (remove-break)
   (make-instance of PERSON (name "Bob")) (send [bob] greet) (instance-address [bob]) (delete-instance) (unmake-instance [bob])
   (slot-value [bob] name) (class PERSON) (superclassp PERSON USER) (class-slots PERSON) (describe-class PERSON))

; Constants, literals and syntax oddities
(defglobal ?*pi* = 3.14159 ?*name* = "Warehouse" ?*sym* = symbol ?*inst* = [instance-1])
(assert (comma-demo 1,2) (empty) (string "with \"escaped\" quotes and \\ backslash") (float 1.0e10) (neg -3) (exp 1E-3) (sym-with_chars! a.b *c* <d>))
(bind ?tricky (create$ ?x ?y $?z ?*pi* =(+ 1 2) ))
(bind ?inst [my-instance])
(bind ?addr <Fact-1>)
(bind ?unicode "café – ünïcode")
(printout t "Done" crlf)
; TODO: split the rule base into modules per department.

; ── CLIPS 6.4: fact-set and instance-set queries ────────────────────
(deffunction fact-queries ()
   (any-factp ((?f item)) (< ?f:qty 5))
   (find-fact ((?f item)) (eq ?f:sku A-100))
   (find-all-facts ((?f item)) (> ?f:qty 10))
   (do-for-fact ((?f item)) (eq ?f:sku B-200) (printout t ?f:name crlf))
   (do-for-all-facts ((?a item) (?b item)) (and (neq ?a ?b) (eq ?a:category ?b:category))
      (printout t ?a:sku " " ?b:sku crlf))
   (delayed-do-for-all-facts ((?f item)) (= ?f:qty 0) (retract ?f))
   (any-instancep ((?p PERSON)) (> ?p:age 65))
   (find-instance ((?p PERSON)) (eq ?p:name "Alice"))
   (find-all-instances ((?p PERSON)) TRUE)
   (do-for-instance ((?p PERSON)) (eq ?p:name "Bob") (send ?p greet))
   (do-for-all-instances ((?p PERSON)) TRUE (send ?p greet))
   (delayed-do-for-all-instances ((?p PERSON)) (< ?p:age 18) (send ?p delete)))

; ── Generic functions and methods with restrictions ─────────────────
(defgeneric combine)
(defmethod combine ((?a INTEGER) (?b INTEGER)) (+ ?a ?b))
(defmethod combine ((?a NUMBER) (?b NUMBER)) (+ ?a ?b))
(defmethod combine ((?a STRING) (?b STRING)) (str-cat ?a ?b))
(defmethod combine ((?a SYMBOL) $?rest) (create$ ?a ?rest))
(defmethod combine ((?a LEXEME (neq ?a none)) (?b MULTIFIELD)) (create$ ?a ?b))
(defmethod combine ((?a INTEGER (> ?a 0)) (?b FLOAT)) (call-next-method))
(defmethod combine 5 ((?a PERSON) (?b PERSON)) (str-cat ?a:name ?b:name))
(defmethod combine (?x ?y) (override-next-method ?x ?y))

; ── Classes: facets, handlers of every type, accessors ──────────────
(defclass ANIMAL
   (is-a USER)
   (role abstract)
   (pattern-match non-reactive)
   (slot name (access read-only) (storage local) (visibility public) (create-accessor read) (override-message name-changed))
   (slot legs (type INTEGER) (default 4) (propagation inherit) (source composite) (access initialize-only))
   (slot owner (type INSTANCE-NAME) (default [nobody]))
   (multislot tags (default-dynamic (create$)) (cardinality 0 10))
   (slot weight (type FLOAT NUMBER) (range 0.0 ?VARIABLE) (access read-write) (storage shared)))

(defclass DOG
   (is-a ANIMAL)
   (role concrete)
   (slot breed (type SYMBOL) (allowed-symbols lab collie other) (default other)))

(defmessage-handler ANIMAL speak primary () (printout t "..." crlf))
(defmessage-handler DOG speak primary () (printout t "Woof" crlf))
(defmessage-handler DOG speak before () (printout t "[before] "))
(defmessage-handler DOG speak after () (printout t " [after]" crlf))
(defmessage-handler DOG speak around () (call-next-handler))
(defmessage-handler DOG init after () (printout t "initialised" crlf))
(defmessage-handler DOG delete before () (printout t "deleting" crlf))
(defmessage-handler DOG put-name primary (?value) (dynamic-put name ?value))
(defmessage-handler DOG get-name primary () (dynamic-get name))
(defmessage-handler DOG describe primary ($?extras)
   (printout t ?self:name " (" ?self:breed ") " ?extras crlf)
   (bind ?x (override-next-handler))
   (next-handlerp))

(definstances dogs
   (rex of DOG (name "Rex") (breed lab))
   ([fido] of DOG (name "Fido") (tags small friendly)))

(deffunction message-demo ()
   (make-instance rex2 of DOG (name "Rex2"))
   (send [rex2] speak)
   (send [rex2] put-name "Renamed")
   (send (instance-address * [rex2]) describe 1 2 3)
   (slot-direct-accessor DOG breed)
   (ppinstance)
   (instances)
   (unmake-instance [rex2])
   (class-existp DOG)
   (subclassp DOG ANIMAL)
   (class-subclasses ANIMAL inherit)
   (message-handler-existp DOG speak primary)
   (list-defmessage-handlers DOG inherit)
   (undefclass DOG)
   (undefinstances dogs))

; ── Modules: every import/export form ───────────────────────────────
(defmodule INVENTORY
   (export deftemplate item reorder)
   (export defclass ?ALL)
   (export deffunction average)
   (export defgeneric combine)
   (export defglobal ?NONE))

(defmodule ORDERS
   (import INVENTORY deftemplate item)
   (import INVENTORY defclass ?ALL)
   (import INVENTORY deffunction ?ALL)
   (import INVENTORY ?ALL))

(deftemplate INVENTORY::stocked (slot sku))
(defrule ORDERS::place-order
   (declare (salience -10) (dynamic-salience TRUE))
   (INVENTORY::item (sku ?s) (qty 0))
   =>
   (focus INVENTORY ORDERS)
   (printout t "ordering " ?s crlf)
   (get-current-module)
   (set-current-module ORDERS))

; ── Activation control, strategies and tracing ──────────────────────
(deffunction control-surface ()
   (set-strategy simplicity)
   (set-strategy complexity)
   (set-strategy lex)
   (set-strategy mea)
   (set-strategy random)
   (set-strategy breadth)
   (set-incremental-reset TRUE)
   (set-fact-duplication FALSE)
   (set-dynamic-constraint-checking TRUE)
   (set-static-constraint-checking FALSE)
   (set-reset-globals TRUE)
   (set-sequence-operator-recognition TRUE)
   (set-conserve-memory TRUE)
   (watch all) (watch facts) (watch activations) (watch compilations) (watch statistics)
   (watch focus) (watch globals) (watch instances) (watch slots) (watch messages)
   (watch message-handlers) (watch generic-functions) (watch methods) (watch deffunctions)
   (unwatch facts)
   (run 10) (run -1)
   (agenda INVENTORY)
   (refresh-agenda)
   (halt)
   (save-facts "facts.dat" local) (load-facts "facts.dat") (save "kb.clp") (bsave "kb.bin") (bload "kb.bin")
   (checkpoint) (get-auto-float-dividend) (set-auto-float-dividend TRUE)
   (defrule-module low-stock) (list-defmodules) (get-defmodule-list))

; ── Rule conditional elements and expressions in full ───────────────
(defrule all-conditional-elements
   (declare (salience 0) (auto-focus FALSE) (node-index-hash FALSE))
   ?a <- (item (sku ?s) (qty ?q&:(> ?q 0)))
   ?b <- (reorder (sku ?s))
   (item (sku ?other&~?s) (qty =(+ ?q 1)))
   (item (sku ?s2) (qty ?q2&:(and (>= ?q2 1) (<= ?q2 10) (neq ?q2 5))))
   (or (and (item (sku A-100)) (item (sku B-200))) (not (item)))
   (exists (item (sku ?e)) (reorder (sku ?e)))
   (forall (item (sku ?f)) (reorder (sku ?f)))
   (logical (item (sku ?l)) (and (reorder (sku ?l))))
   (test (> ?q 0))
   (not (item (sku ?s) (qty ?z&:(< ?z 0))))
   =>
   (retract ?a ?b)
   (assert (item (sku new) (qty (+ ?q 1))) (reorder (sku ?s) (amount 1)))
   (modify ?a (qty (- ?q 1)) (tags a b))
   (duplicate ?a (sku copy))
   (printout t "done" crlf)
   (return))
