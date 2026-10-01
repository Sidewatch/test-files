;;;; Common Lisp (ANSI X3.226-1994, as implemented by SBCL 2.5 and CCL) — syntax showcase
;;;; Warehouse inventory in Common Lisp.
;;;; Four semicolons mark file headers; three, sections; two, code blocks;
;;;; one, trailing remarks.
;;; TODO: persist the stock table between runs.

#|
  A block comment.
  #| Block comments nest. |#
|#

(defpackage :warehouse
  (:use :cl)
  (:nicknames :wh)
  (:shadow #:search)
  (:import-from :alexandria #:when-let #:with-gensyms)
  (:export #:fib #:describe-account #:*stock* #:main))

(in-package :warehouse)

;;; ── Special variables and constants ───────────────────────────────────

(defvar *stock* (make-hash-table :test 'equal) "Table of SKU to quantity.")
(defparameter *reorder-point* 25)
(defconstant +tax-rate+ 0.2d0)
(defconstant +greeting+ "Hello, warehouse")
(declaim (type fixnum *reorder-point*))
(declaim (inline square))
(declaim (optimize (speed 1) (safety 3) (debug 2)))

;;; ── Literals ──────────────────────────────────────────────────────────

(list 42 -7 +5 1/3 -22/7 3.14 1.5e-3 1.5d0 2.5f0 6.02s23 #xFF #b1010 #o755 #36rZZ)
(list #c(1 2) #c(1.5 -2.5) 1. .5)
(list #\a #\Space #\Newline #\Tab #\Rubout #\Nul #\é #\x41 #\U+00E9)
(list "string with \"escapes\" and \\ backslash"
      "multi-line
string")
(list 'symbol :keyword 'pkg:external 'pkg::internal '|Mixed Case Symbol| 'sym\ with\ spaces)
(list #:uninterned #'car #'(lambda (x) x) '(a . b) '(1 2 . 3) '(quote x) ''x)
(list nil t)
(list #(1 2 3) #*1011 #p"/tmp/stock.dat" #P"relative/path.lisp")
(list #.(+ 1 2) #+sbcl :on-sbcl #-sbcl :elsewhere #+(or sbcl ccl) :fast #-(and) :never)
(list #1=(a b . #1#) #2# #S(point :x 1 :y 2))
(list `(a ,b ,@c ,'d ,(+ 1 2)) '#:g1)
(list pi most-positive-fixnum char-code-limit)

;;; ── Functions ─────────────────────────────────────────────────────────

(defun square (x)
  "Return X squared."
  (* x x))

(defun fib (n)
  "The nth Fibonacci number, memoised."
  (declare (type (integer 0) n))
  (or (gethash n *fib-cache*)
      (setf (gethash n *fib-cache*)
            (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))))

(defvar *fib-cache* (make-hash-table))

(defun make-item (sku &optional (qty 0) (price 0.0 price-supplied-p) &rest tags &key category ((:name n) "unnamed") &allow-other-keys)
  (list sku qty price price-supplied-p tags category n))

(defun with-aux (a &aux (b (* a 2)) c)
  (declare (ignore c))
  (+ a b))

(defun (setf stock-of) (new-value sku)
  (setf (gethash sku *stock*) new-value))

(defgeneric describe-account (account)
  (:documentation "Describe an account.")
  (:method ((a null)) "nothing"))

(defmacro unless-empty ((var list) &body body)
  `(let ((,var ,list))
     (unless (null ,var) ,@body)))

(defmacro with-timing (&body body)
  (with-gensyms (start)
    `(let ((,start (get-internal-real-time)))
       (multiple-value-prog1 (progn ,@body)
         (format t "~&took ~d ticks~%" (- (get-internal-real-time) ,start))))))

(define-compiler-macro square (&whole form x)
  (if (numberp x) (* x x) form))

(define-modify-macro incf-by (amount) +)
(defsetf second-of (list) (new) `(setf (second ,list) ,new))
(deftype small-int () '(integer 0 100))
(deftype non-empty-string () '(and string (satisfies plusp-length)))
(define-symbol-macro answer 42)
(declaim (ftype (function (fixnum) fixnum) bump))
(defun bump (n) (the fixnum (1+ n)))

;;; ── CLOS ──────────────────────────────────────────────────────────────

(defclass account ()
  ((owner   :initarg :owner   :reader owner)
   (balance :initarg :balance :accessor balance :initform 0 :type number)
   (history :initform nil :allocation :class)
   (id      :initarg :id :writer set-id :documentation "Identifier."))
  (:default-initargs :balance 0)
  (:documentation "A bank account."))

(defclass savings (account)
  ((rate :initarg :rate :initform 0.02)))

(defmethod describe-account ((a account))
  (format nil "~a has ~,2f" (owner a) (balance a)))

(defmethod describe-account :before ((a savings))
  (format t "Describing a savings account~%"))

(defmethod describe-account :around ((a savings))
  (call-next-method))

(defmethod describe-account ((n (eql 0))) "zero")
(defmethod describe-account ((s string)) s)

(defmethod initialize-instance :after ((a account) &key)
  (setf (slot-value a 'history) nil))

(defmethod print-object ((a account) stream)
  (print-unreadable-object (a stream :type t :identity t)
    (format stream "~a" (owner a))))

(defstruct point (x 0 :type number) (y 0 :type number))
(defstruct (circle (:include point) (:constructor make-circle (x y radius)) (:conc-name c-)) radius)

(define-condition stock-error (error)
  ((sku :initarg :sku :reader error-sku))
  (:report (lambda (c s) (format s "Bad SKU ~a" (error-sku c)))))

(define-method-combination my-or :operator or)

;;; ── Control flow ──────────────────────────────────────────────────────

(defun control-demo (x)
  (cond ((< x 0) :negative)
        ((= x 0) :zero)
        (t :positive))
  (case x ((1 2) :few) (3 :three) ((4) :four) (otherwise :many))
  (ecase x (1 :one) (2 :two))
  (typecase x (integer :int) (string :str) (t :other))
  (if (plusp x) 'yes 'no)
  (when (plusp x) (print x))
  (unless (plusp x) (print "non-positive"))
  (and x (or nil x))
  (not x))

(defun loops ()
  (dotimes (i 3) (print i))
  (dolist (item '(a b c) :done) (print item))
  (do ((i 0 (1+ i)) (acc nil (cons i acc))) ((= i 3) acc))
  (do* ((i 0 (1+ i))) ((= i 3)))
  (loop for i from 1 to 10 by 2
        for x in '(a b c)
        for y across #(1 2 3)
        for (k . v) in '((a . 1))
        when (evenp i) collect i into evens
        else sum i into odds
        while (< i 8)
        until (> i 9)
        do (print i)
        finally (return (values evens odds)))
  (loop repeat 3 do (print "hi"))
  (loop with total = 0 for item being the hash-keys of *stock* using (hash-value qty) do (incf total qty) finally (return total))
  (loop (return))
  (tagbody
   start (print "tag")
         (go end)
   end))

(defun bindings ()
  (let ((a 1) (b 2)) (+ a b))
  (let* ((a 1) (b (* a 2))) b)
  (flet ((helper (x) (* x 2))) (helper 2))
  (labels ((walk (n) (if (zerop n) 0 (walk (1- n))))) (walk 3))
  (macrolet ((twice (x) `(progn ,x ,x))) (twice (print 1)))
  (symbol-macrolet ((x (car cell))) x)
  (multiple-value-bind (q r) (floor 7 2) (list q r))
  (destructuring-bind (a (b c) &rest d) '(1 (2 3) 4 5) (list a b c d))
  (let ((*print-base* 16)) (print 255))
  (progn 1 2) (prog1 1 2) (prog2 1 2 3)
  (block done (return-from done 1))
  (catch 'tag (throw 'tag 1))
  (unwind-protect (print "body") (print "cleanup"))
  (values 1 2 3)
  (setf (values a b) (values 1 2))
  (psetf a b b a)
  (rotatef a b)
  (shiftf a b 3)
  (incf a) (decf b 2) (push 1 stack) (pop stack) (pushnew 1 stack)
  (the integer 1)
  (declare (special *x*)))

(defun errors ()
  (handler-case (error 'stock-error :sku "A-100")
    (stock-error (e) (format t "caught ~a~%" e))
    (error (e) (format t "other ~a~%" e))
    (:no-error (v) v))
  (handler-bind ((warning #'muffle-warning)) (warn "careful"))
  (restart-case (error "oops")
    (use-value (v) v)
    (retry () :retry))
  (ignore-errors (/ 1 0))
  (with-simple-restart (skip "Skip it") (error "x"))
  (assert (plusp 1) (x) "x must be positive ~a" x)
  (check-type x integer)
  (signal 'condition)
  (cerror "Continue" "Problem"))

;;; ── Higher-order and I/O ──────────────────────────────────────────────

(mapcar #'1+ '(1 2 3))
(reduce #'+ '(1 2 3) :initial-value 0)
(remove-if-not #'evenp '(1 2 3 4))
(sort (copy-list '(3 1 2)) #'<)
(funcall #'+ 1 2)
(apply #'+ 1 2 '(3 4))
(lambda (&rest args) (length args))
(maphash (lambda (k v) (format t "~a=~a~%" k v)) *stock*)
(with-open-file (s "stock.dat" :direction :output :if-exists :supersede) (print '(a b) s))
(with-output-to-string (out) (princ "x" out))
(format t "~a ~s ~d ~5,2f ~x ~b ~o ~e ~& ~% ~~ ~{~a~^, ~} ~[zero~;one~:;many~] ~(downcase~) ~@(Capitalise~)~%" 1 "s" 2 3.14159 255 5 8 1.0 '(1 2 3) 1)
(format nil "~10<~a~>~20t~a" 1 2)
(read-from-string "(1 2 3)")
(eval '(+ 1 2))
(compile nil '(lambda (x) x))
(load "other.lisp")
(require :asdf)
(setf *random-state* (make-random-state t))
(provide :warehouse)

;;; ── Entry point ───────────────────────────────────────────────────────

(defun main ()
  (let ((acct (make-instance 'account :owner "Ada" :balance 120.5)))
    (incf (balance acct) (fib 10))          ; +55
    (format t "~a~%" (describe-account acct))))

;;; ── Further constructs ────────────────────────────────────────────────

;;; Reader macros and syntax
(list '#:gensym-like #'identity #'(setf car) '(setf cdr) #'(lambda () nil))
(list #b-101 #o-17 #x-FF #3r12 #c(0 1) #c(1/2 -3/4) #c(1.0d0 2.0d0))
(list 1.0e0 1.0f0 1.0s0 1.0d0 1.0l0 -0.0 +0.5 1.e5 .5e-3 1e3)
(list 'a.b 'a\.b '|a.b| '\a 'ab\cd 'AbC (quote |foo bar|) '|a\|b|)
(list #\( #\) #\; #\" #\' #\` #\, #\# #\\ #\| #\Backspace #\Return #\Linefeed #\Page #\Escape #\Bell)
(list "tab	literal" "line\\nbreak" "unicode é ü 世界" "with ~a directive" "~%")
(list '(a b . c) '(a . (b . (c . nil))) '#(a b) '#2A((1 2) (3 4)) #+nil ignored #-nil kept)
(list #'+ #'(lambda (&optional x) x) (function car) (quote cdr))
(list `(,@'(1 2) . ,(+ 1 2)) `#(1 ,(+ 1 1)) `(a `(b ,(c ,(+ 1 2)))))
(list (read-from-string "#.(+ 1 2)") *read-eval* *package* *readtable*)
(set-macro-character #\! (lambda (stream char) (declare (ignore char)) (list 'not (read stream t nil t))))
(set-dispatch-macro-character #\# #\? (lambda (s c n) (declare (ignore c n)) (read s t nil t)))
(set-syntax-from-char #\] #\))
(make-dispatch-macro-character #\@)

;;; Declarations and types
(declaim (type (simple-array (unsigned-byte 8) (*)) *buffer*)
         (ftype (function (integer &optional integer) (values integer &optional)) add)
         (notinline helper)
         (dynamic-extent *temp*)
         (optimize (speed 3) (safety 0) (debug 0) (space 1) (compilation-speed 0)))
(deftype octet () '(unsigned-byte 8))
(deftype matrix (&optional (rows '*) (cols '*)) `(array number (,rows ,cols)))
(defun typed (x y)
  (declare (type fixnum x) (type (integer 0 100) y) (ignorable x) (optimize speed)
           (special *dynamic*) (dynamic-extent y) (inline +))
  (the fixnum (+ x y)))
(defstruct (account-struct (:conc-name acct-) (:copier nil) (:predicate is-acct) (:print-function print-acct) (:type vector) :named (:initial-offset 1))
  "Docstring for the struct."
  (id 0 :type integer :read-only t)
  (balance 0.0 :type float))
(defstruct (extended (:include account-struct (balance 100.0))) extra)

;;; Packages and systems
(defpackage #:warehouse-tests (:use #:cl #:warehouse) (:local-nicknames (#:a #:alexandria)) (:documentation "Tests."))
(in-package #:warehouse-tests)
(rename-package :old :new '(:alias))
(use-package :alexandria)
(unuse-package :alexandria)
(import 'warehouse::internal-fn)
(export '(public-fn))
(shadowing-import 'a:flatten)
(do-symbols (s :warehouse) (print s))
(do-external-symbols (s :warehouse) (print s))
(with-package-iterator (next :warehouse :external) (next))
(find-symbol "FIB" :warehouse)
(intern "DYNAMIC" :warehouse)
(delete-package :obsolete)
(asdf:defsystem :warehouse
  :description "Warehouse system"
  :version "1.0.0"
  :author "Acme"
  :license "MIT"
  :depends-on (:alexandria :cl-ppcre (:version :fiveam "1.0"))
  :serial t
  :components ((:file "package") (:module "src" :components ((:file "stock") (:file "report"))))
  :in-order-to ((test-op (test-op :warehouse/tests))))
(ql:quickload :warehouse :silent t)

;;; Condition system, in more depth
(define-condition low-stock (warning)
  ((sku :initarg :sku :accessor low-stock-sku :initform nil)
   (qty :initarg :qty :reader low-stock-qty))
  (:default-initargs :qty 0)
  (:report (lambda (condition stream)
             (format stream "Low stock for ~a: ~d" (low-stock-sku condition) (low-stock-qty condition))))
  (:documentation "Signalled when stock is low."))
(defun check-stock (sku qty)
  (restart-case (when (< qty 25) (warn 'low-stock :sku sku :qty qty))
    (continue () :report "Ignore and continue." nil)
    (use-value (v) :report "Use another quantity." :interactive (lambda () (list (read))) v)))
(handler-bind ((low-stock (lambda (c) (invoke-restart 'continue))))
  (check-stock "A-100" 3))
(handler-case (check-stock "B-200" 5)
  (low-stock (c) (format t "~a~%" c))
  (serious-condition (c) (abort))
  (:no-error (&rest values) values))
(with-condition-restarts c (list (find-restart 'continue)) (signal c))
(compute-restarts)
(invoke-debugger (make-condition 'simple-error :format-control "x"))
(setf *debugger-hook* nil)
(break "Breakpoint ~a" 1)
(trace fib)
(untrace fib)
(step (fib 5))
(time (fib 20))
(describe 'fib)
(inspect *stock*)
(documentation 'fib 'function)
(apropos "STOCK")
(room)
(ed "file.lisp")
(dribble "log.txt")

;;; Data structures and sequences, wide
(let ((v (make-array 5 :initial-element 0 :adjustable t :fill-pointer 0 :element-type 'fixnum))
      (h (make-hash-table :test #'equalp :size 100 :rehash-size 1.5 :weakness :key))
      (s (make-string 3 :initial-element #\a))
      (b (make-array 8 :element-type 'bit :initial-contents '(1 0 1 0 1 0 1 0)))
      (l (list 1 2 3))
      (al '((a . 1) (b . 2)))
      (pl '(:a 1 :b 2)))
  (vector-push-extend 1 v)
  (setf (gethash "k" h) 1 (aref v 0) 2 (char s 0) #\b (bit b 0) 0 (nth 0 l) 9 (getf pl :a) 5 (cdr (assoc 'a al)) 7)
  (remf pl :b)
  (push 1 (cdr l))
  (list (length v) (reverse l) (subseq l 1) (position 2 l) (find 2 l) (count 1 l) (member 2 l) (assoc 'a al)
        (remove 1 l) (delete 1 l) (substitute 0 1 l) (mismatch l l) (search '(2) l) (every #'numberp l)
        (some #'evenp l) (notany #'null l) (reduce #'max l) (merge 'list l l #'<) (stable-sort l #'<)
        (concatenate 'string "a" "b") (coerce l 'vector) (map 'list #'1+ l) (mapcan #'list l) (mapl #'identity l)
        (union l l) (intersection l l) (set-difference l l) (adjoin 4 l) (subsetp l l) (last l) (butlast l)
        (copy-tree l) (tree-equal l l) (sublis al l) (acons 'c 3 al) (pairlis '(a) '(1)) (rassoc 1 al)
        (string-upcase "a") (string-trim " " " a ") (string= "a" "a") (string-lessp "a" "b") (char-code #\a)
        (parse-integer "42") (princ-to-string 42) (prin1-to-string "s") (format nil "~r" 42) (digit-char-p #\7)
        (logand 5 3) (logior 5 3) (logxor 5 3) (lognot 5) (ash 1 4) (ldb (byte 4 0) 255) (dpb 1 (byte 1 0) 0)
        (floor 7 2) (ceiling 7 2) (truncate 7 2) (round 7 2) (mod 7 2) (rem 7 2) (gcd 12 18) (lcm 4 6) (expt 2 10)
        (sqrt -1) (exp 1) (log 100 10) (sin 0) (atan 1 1) (random 10) (numerator 1/2) (denominator 1/2)
        (get-universal-time) (get-decoded-time) (sleep 0) (machine-instance) (lisp-implementation-type)))

;;; Streams, pathnames and I/O
(with-open-file (in "input.txt" :direction :input :element-type 'character :external-format :utf-8 :if-does-not-exist nil)
  (loop for line = (read-line in nil) while line collect line))
(with-open-file (out #p"output.bin" :direction :output :element-type '(unsigned-byte 8) :if-exists :append :if-does-not-exist :create)
  (write-byte 255 out))
(with-input-from-string (s "1 2 3") (list (read s) (read s) (read s)))
(directory "*.lisp")
(probe-file "stock.dat")
(merge-pathnames "file.txt" "/tmp/")
(make-pathname :directory '(:absolute "tmp") :name "stock" :type "dat")
(pathname-name #p"/tmp/stock.dat")
(delete-file "stock.dat")
(rename-file "a" "b")
(ensure-directories-exist "/tmp/stock/")
(write-string "text" *standard-output*)
(write-line "line")
(terpri)
(fresh-line)
(finish-output)
(print-unreadable-object (*stock* *standard-output* :type t :identity t))
(let ((*print-pretty* t) (*print-circle* t) (*print-readably* nil) (*print-length* 10) (*print-level* 3) (*print-right-margin* 80))
  (pprint '(defun f (x) (if x 1 2))))
(pprint-logical-block (*standard-output* '(1 2 3) :prefix "(" :suffix ")") (pprint-exit-if-list-exhausted) (write 1))
(format t "~:[false~;true~] ~#[none~;one~:;many~] ~v,vd ~?~%" t 5 3 7 "~a" '(x))
(format t "~{~a~^, ~}~%~@{~a~^ ~}" '(1 2 3) 4 5)
(format t "~<~%~1,20:;~a~>" "justified")
(format t "~(~a~) ~:@(~a~) ~:(~a~) ~/warehouse::custom-directive/" "LOWER" "upper" "cap" 1)
(read-char) (peek-char) (unread-char #\a) (read-byte in) (listen) (clear-input) (read-sequence buffer in)
;; TODO: move the format strings into a message catalogue.

;;; ── CLOS in full: slots, metaclasses, protocols ─────────────────────

(defclass shape ()
  ((name :initarg :name :initform "shape" :reader shape-name :type string)
   (sides :initarg :sides :accessor shape-sides :initform 0 :allocation :instance)
   (count :allocation :class :initform 0 :accessor shape-count))
  (:metaclass standard-class)
  (:default-initargs :name "unnamed")
  (:documentation "Base class for shapes."))

(defclass polygon (shape) ((vertices :initarg :vertices :accessor vertices :initform nil)))
(defclass coloured-mixin () ((colour :initarg :colour :initform :black :accessor colour)))
(defclass coloured-polygon (polygon coloured-mixin) ())

(defgeneric area (shape)
  (:documentation "The area of SHAPE.")
  (:generic-function-class standard-generic-function)
  (:method-combination +)
  (:method ((s shape)) 0)
  (declare (optimize speed)))

(defgeneric combine (a b) (:method-combination progn))
(defmethod combine progn ((a shape) (b shape)) :both-shapes)
(defmethod combine progn ((a polygon) b) :polygon-first)

(defmethod area ((p polygon))
  (with-slots (vertices) p
    (length vertices)))

(defmethod area :around ((p coloured-polygon))
  (with-accessors ((c colour) (v vertices)) p
    (if (eq c :transparent) 0 (call-next-method))))

(defmethod (setf shape-name) :before (new (s shape)) (declare (ignore new)) (print "renaming"))
(defmethod shared-initialize :after ((s shape) slot-names &rest initargs &key &allow-other-keys)
  (declare (ignore slot-names initargs))
  (incf (shape-count s)))
(defmethod make-load-form ((s shape) &optional environment)
  (make-load-form-saving-slots s :environment environment))
(defmethod update-instance-for-different-class :before ((old shape) (new polygon) &key)
  nil)
(defmethod slot-missing (class instance slot-name operation &optional new-value)
  (declare (ignore class instance operation new-value))
  (error "No slot ~a" slot-name))

(let ((p (make-instance 'coloured-polygon :vertices '(1 2 3) :colour :red)))
  (change-class p 'polygon)
  (slot-value p 'vertices)
  (slot-boundp p 'vertices)
  (slot-exists-p p 'vertices)
  (slot-makunbound p 'vertices)
  (class-of p)
  (find-class 'polygon)
  (typep p 'shape)
  (subtypep 'polygon 'shape)
  (reinitialize-instance p :vertices nil)
  (describe p)
  (ensure-generic-function 'area)
  (no-applicable-method #'area p)
  (compute-applicable-methods #'area (list p))
  (find-method #'area '() (list (find-class 'polygon)))
  (remove-method #'area (find-method #'area '() (list (find-class 'polygon))))
  (slot-value p 'vertices))

;;; ── Evaluation control, compilation, and environment ────────────────

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *compile-time-constant* 42))
(defmacro compile-time-value () (load-time-value *compile-time-constant*))
(locally (declare (optimize (safety 0))) (+ 1 2))
(multiple-value-call #'list (values 1 2) (values 3))
(nth-value 1 (floor 7 2))
(multiple-value-setq (a b) (values 1 2))
(multiple-value-list (values 1 2 3))
(values-list '(1 2 3))
(let ((fn (compile nil '(lambda (x) (* x x))))) (funcall fn 4))
(compile-file "warehouse.lisp" :output-file "warehouse.fasl" :verbose t)
(load "warehouse.fasl" :verbose nil :print nil)
(macroexpand-1 '(unless-empty (x '(1)) x))
(macroexpand '(incf-by x 2))
(constantp 42)
(special-operator-p 'if)
(macro-function 'when)
(fboundp 'fib)
(fmakunbound 'old)
(boundp '*stock*)
(makunbound '*scratch*)
(symbol-value '*reorder-point*)
(symbol-function 'fib)
(symbol-plist 'fib)
(get 'fib 'property)
(setf (get 'fib 'property) t)
(function-lambda-expression #'fib)
(proclaim '(optimize (speed 1)))
(defconstant +answer+ 42 "The answer.")
(defvar *unbound*)
(defparameter *lexical-note* "special variable naming convention")
(sb-ext:*gc-run-time*)
(sb-ext:quit :unix-status 0)
#+sbcl (sb-ext:gc :full t)
#+(and sbcl (not ccl)) (sb-ext:disable-debugger)
#+ccl (ccl:gc)
#-(or sbcl ccl clisp) (error "Unsupported implementation")
#+#.(cl:if (cl:find-package "SWANK") '(and) '(or)) (print "swank")

;;; ── Loop, in every clause family ────────────────────────────────────

(loop named outer
      for i from 0 below 10
      for j downfrom 10 to 0 by 2
      for k upfrom 1
      for e in '(1 2 3) by #'cddr
      for (a b) on '(1 2 3 4) by #'cddr
      for x = 1 then (* x 2)
      for ch across "abc"
      for s being the symbols of :cl
      for k2 being each hash-key of (make-hash-table) using (hash-value v)
      for p being the present-symbol in :cl
      for e2 being the elements of #(1 2 3) using (index ix)
      with total = 0 and count = 0
      as y = (random 10)
      initially (print "start")
      collect i into all
      append (list i j)
      nconc (list k)
      count (evenp i)
      sum i into s2 of-type fixnum
      maximize i
      minimize j
      thereis (> i 5)
      always (>= i 0)
      never (< i 0)
      do (setf total (+ total i))
      if (evenp i) collect i else collect (- i) end
      when (> i 3) do (print i) and sum i end
      unless (< i 0) do (print j)
      with-result = nil
      repeat 5
      while (< i 8)
      until (> j 20)
      finally (return-from outer (values all total))
      finally (return (list all total)))

;;; ── Format directives, comprehensively ──────────────────────────────

(format nil "~a ~s ~d ~b ~o ~x ~r ~:r ~@r ~c ~e ~f ~g ~$ ~% ~& ~| ~~ ~t ~* ~? ~p" 1 "s" 2 3 4 255 5 6 7 #\a 1.5 2.5 3.5 4.5)
(format nil "~10a|~10@a|~-5,2f|~,3e|~8,'0d|~:d|~@d|~,,'.,4:d" "left" "right" 3.14159 12345.678 42 1234567 5 1234567)
(format nil "~{~a~^, ~}|~:{(~a ~a)~}|~@{~a~}|~:@{~a~}" '(1 2 3) '((1 2) (3 4)) 1 2 3)
(format nil "~[a~;b~;c~:;other~]|~:[no~;yes~]|~@[present ~a~]|~#[none~;one~:;~a~]" 1 t 5)
(format nil "~(UPPER~)|~@(first cap~)|~:(each word~)|~:@(ALL~)|~<~%~1,10:;wrapped~>|~;~>")
(format nil "~V,'*D|~#,'xd|~3*~a|~2@*~a|~@*~a" 5 42 0 'a 'b 'c 'd)
(format nil "~/pprint-fill/~/my-package:my-directive/" '(1 2) 3)
(format nil "~_~:_~@_~:@_~I~:I~W~<~:>")
(format nil "~2,1,0,'*,'_,3e" 12345.6)

;;; ── Streams, strings and characters, spelled out ────────────────────

(list (char-upcase #\a) (char-name #\Space) (name-char "Newline") (code-char 955) (char-int #\a)
      (digit-char 7) (alpha-char-p #\a) (alphanumericp #\1) (upper-case-p #\A) (both-case-p #\a)
      (string #\a) (make-string 2 :initial-element #\-) (string-capitalize "hello world") (nstring-downcase (copy-seq "ABC"))
      (string-left-trim " " "  x") (string-right-trim " " "x  ") (subseq "hello" 1 3) (concatenate 'string "a" "b")
      (with-output-to-string (s) (write-char #\a s) (write-string "bc" s))
      (string-not-equal "a" "b") (string-greaterp "b" "a") (string/= "a" "b") (char< #\a #\b) (char-equal #\a #\A)
      (parse-integer "ff" :radix 16 :junk-allowed t) (read-from-string "#x1F") (write-to-string 255 :base 2 :radix t)
      (intern (string-upcase "sym")) (symbol-name 'sym) (gensym "G") (gentemp "T") (make-symbol "S") (keywordp :k)
      (list #\Newline #\Tab #\Page #\Backspace #\Rubout #\Space #\Return #\Linefeed))
