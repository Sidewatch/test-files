#!/usr/bin/env guile
!#
;;; ── Comments ──
;;; Scheme (R7RS + common extensions) showcase: warehouse inventory.
;; TODO: persist the stock. FIXME: reorder amounts ignore pack sizes.
; A single-semicolon comment, usually at the end of a line.

#| A block comment
   #| with a nested block comment |#
   spanning lines. |#

#;(this whole datum is commented out)
(display #;ignored "datum comment inside a form")

#!fold-case
#!no-fold-case

;;; ── Libraries and imports ──
(define-library (warehouse stock)
  (export make-counter revenue (rename internal-total total))
  (import (scheme base) (scheme write) (scheme char) (scheme cxr) (scheme inexact)
          (scheme complex) (scheme lazy) (scheme case-lambda) (scheme eval)
          (scheme file) (scheme read) (scheme repl) (scheme process-context)
          (scheme time) (scheme load) (scheme r5rs)
          (only (srfi 1) fold filter reduce)
          (prefix (srfi 69) ht:)
          (rename (srfi 8) (receive rcv))
          (except (srfi 13) string-index))
  (include "helpers.scm")
  (include-ci "case-insensitive.scm")
  (include-library-declarations "more.sld")
  (cond-expand
    (guile (import (guile)))
    ((and r7rs (not chicken)) (import (scheme base)))
    ((or full-unicode ratios) (begin (define unicode? #t)))
    ((library (srfi 1)) (import (srfi 1)))
    (else (begin (define portable? #t))))
  (begin
    (define (internal-total orders) (revenue orders))))

(import (scheme base) (scheme write))
(use-modules (ice-9 format) (srfi srfi-1))
(require-extension (srfi 1))

;;; ── Literals ──
(define booleans (list #t #f #true #false))
(define numbers
  (list 42 -7 +5 3.14 -2.5e3 1e-3 6.022E23 .5 5. #xFF #b1010 #o755 #d10
        #e1.5 #i3/4 #x-1F #e1e3 1/2 -3/4 +inf.0 -inf.0 +nan.0 -nan.0
        1+2i 3.0-4.5i +i -i 1@2 #xFF/2))
(define chars
  (list #\a #\A #\space #\newline #\tab #\return #\nul #\null #\alarm #\backspace
        #\delete #\escape #\x41 #\x3BB #\λ #\( #\) #\; #\" #\#))
(define strings
  (list "plain string"
        "escapes: \a \b \t \n \r \" \\ \| \x41; \x3BB; unicode λ 📦"
        "line continuation: \
         joined"
        "multi-line
string"
        ""))
(define symbols
  (list 'sym 'with-dash 'q? 'set! '<=? '->arrow '... '+ '- '1+ '|symbol with spaces|
        '|pipes \| inside| 'λ 'CamelCase '$dollar '%percent '&amp '*star* '/slash '^caret '~tilde '_under))
(define keywords (list #:keyword keyword: #:another-kw))   ; Guile and others
(define quoted-forms
  (list ''a '`(a ,b ,@c) '(a . b) '(1 . (2 . (3 . ()))) '#(1 2 3) '#u8(0 255) '()))
(define vectors (list #(1 2 3) #() #(a #(nested))))
(define bytevectors (list #u8(1 2 3) #u8()))
(define datum-labels '#0=(a b . #0#))
(define datum-label-2 '(#1=(x y) #1#))
(define special-objects (list (if #f #f) (eof-object) #!default #!eof #!unspecific #!optional #!rest #!key))

;;; ── Definitions ──
(define pi 3.14159)
(define reorder-point 25)
(define (add a b) (+ a b))
(define (varargs . rest) (apply + rest))
(define (mixed a b . rest) (list a b rest))
(define (optional a #!optional (b 2)) (+ a b))
(define-values (quotient* remainder*) (floor/ 17 5))
(define-record-type <order>
  (make-order number total status)
  order?
  (number order-number)
  (total order-total set-order-total!)
  (status order-status))
(define-record-type point (make-point x y) point? (x point-x) (y point-y set-point-y!))
(define-syntax swap!
  (syntax-rules ()
    ((_ a b) (let ((tmp a)) (set! a b) (set! b tmp)))))
(define-syntax unless*
  (syntax-rules (else)
    ((_ test body ...) (if (not test) (begin body ...)))
    ((_ test (else alt) ...) (if test alt ...))))
(define-syntax my-or
  (er-macro-transformer
    (lambda (form rename compare) `(,(rename 'or) ,@(cdr form)))))
(define-syntax while
  (syntax-rules ()
    ((_ cond body ...) (let lp () (when cond body ... (lp))))))
(let-syntax ((foo (syntax-rules () ((_ x) x)))) (foo 1))
(letrec-syntax ((bar (syntax-rules () ((_ x) x)))) (bar 2))
(define-syntax ell
  (syntax-rules ::: ()
    ((_ x :::) (list x :::))))
(define-syntax nested-ellipsis
  (syntax-rules ()
    ((_ (a b ...) ...) '((a ... ) (b ... ...)))))
(define-syntax escaped-ellipsis
  (syntax-rules ()
    ((_ x) '(x (... ...)))))
(define-syntax with-underscore
  (syntax-rules ()
    ((_ _ x) x)))

;;; ── Functions and closures ──
(define (make-counter step)
  (let ((count 0))
    (lambda ()
      (set! count (+ count step))
      count)))

(define (fold f init lst)
  (if (null? lst)
      init
      (fold f (f init (car lst)) (cdr lst))))

(define compose (lambda fs (lambda (x) (fold (lambda (acc f) (f acc)) x (reverse fs)))))
(define case-lam
  (case-lambda
    ((x) x)
    ((x y) (+ x y))
    ((x . rest) (apply + x rest))))

(define orders '((1 120.5 paid) (2 42 pending) (3 0 cancelled)))

(define (revenue orders)
  (fold (lambda (acc o) (if (eq? (caddr o) 'paid) (+ acc (cadr o)) acc)) 0 orders))

(define tick (make-counter 5))
(tick) (tick)

;;; ── Control flow ──
(define (classify n)
  (cond
    ((< n 0) 'negative)
    ((= n 0) 'zero)
    ((assv n '((1 . one) (2 . two))) => cdr)
    ((and (> n 0) (< n 10)) 'small)
    (else 'large)))

(define (dispatch x)
  (case x
    ((1 2 3) 'low)
    ((a b) 'letter)
    ((#\x) 'char)
    ((4) => (lambda (v) (* v 2)))
    (else => (lambda (v) v))))

(define (conditions x)
  (if (zero? x) 'zero 'nonzero)
  (when (> x 0) (display "positive") (newline))
  (unless (> x 0) (display "not positive") (newline))
  (and 1 2 x)
  (or #f x)
  (not x))

(define (binding-forms)
  (let ((a 1) (b 2)) (+ a b))
  (let* ((a 1) (b (+ a 1))) b)
  (letrec ((even? (lambda (n) (if (zero? n) #t (odd? (- n 1)))))
           (odd? (lambda (n) (if (zero? n) #f (even? (- n 1))))))
    (even? 10))
  (letrec* ((a 1) (b (+ a 1))) b)
  (let-values (((q r) (floor/ 17 5))) (list q r))
  (let*-values (((a b) (values 1 2)) ((c) (values (+ a b)))) c)
  (receive (q r . rest) (values 1 2 3) (list q r rest))
  (call-with-values (lambda () (values 1 2)) +)
  (let loop ((i 0) (acc '()))
    (if (< i 3) (loop (+ i 1) (cons i acc)) (reverse acc)))
  (do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 5) sum) (display i))
  (let () (define x 1) (define-values (y z) (values 2 3)) (+ x y z)))

(define (parameters)
  (define p (make-parameter 10 (lambda (x) (* x 2))))
  (parameterize ((p 20)) (p))
  (define s (delay (+ 1 2)))
  (force s)
  (define s2 (make-promise 5))
  (delay-force (delay 1))
  (define-values (a . rest) (values 1 2 3))
  (fluid-let ((reorder-point 30)) reorder-point))

;;; ── Exceptions and continuations ──
(define (safe-div a b)
  (guard (e ((string? e) (display e) 0)
            ((error-object? e) (display (error-object-message e)) -1)
            ((symbol? e) => (lambda (x) x))
            (else (raise e)))
    (if (zero? b) (raise 'div-by-zero) (/ a b))))

(define (with-handlers)
  (with-exception-handler
    (lambda (e) (display "caught") 42)
    (lambda () (+ 1 (raise-continuable 'oops))))
  (error "Something failed:" 'sku "AC-1001" 42)
  (call/cc (lambda (k) (k 1)))
  (call-with-current-continuation (lambda (k) (dynamic-wind (lambda () 'in) (lambda () (k 2)) (lambda () 'out))))
  (call-with-escape-continuation (lambda (k) (k 3)))
  (file-error? 'x)
  (read-error? 'x)
  (error-object-irritants 'x)
  (exit 0)
  (emergency-exit 1))

;;; ── Data structures and standard procedures ──
(define lst (list 1 2 3))
(define alist '((a . 1) (b . 2)))
(car lst) (cdr lst) (cadr lst) (cddr lst) (caddr lst) (caar alist)
(cons 1 2) (list-tail lst 1) (list-ref lst 0) (length lst) (append lst '(4)) (reverse lst)
(map + '(1 2) '(3 4)) (for-each display lst) (vector-map + #(1 2) #(3 4)) (vector-for-each display #(1 2))
(string-map char-upcase "abc") (string-for-each display "abc")
(assq 'a alist) (assv 1 '((1 . x))) (assoc "a" '(("a" . 1)) string=?) (member 2 lst) (memq 'a '(a b)) (memv 1 lst)
(vector-ref #(1 2 3) 0) (vector-set! (make-vector 3 0) 0 1) (vector->list #(1 2)) (list->vector '(1 2)) (vector-fill! (make-vector 2) 0)
(string-append "a" "b") (substring "hello" 1 3) (string-length "abc") (string-upcase "a") (string->number "42") (number->string 42 2)
(string->symbol "a") (symbol->string 'a) (string->list "abc") (list->string '(#\a)) (string-copy "abc") (string-ref "abc" 0)
(char->integer #\a) (integer->char 97) (char-alphabetic? #\a) (char-numeric? #\1) (char-upcase #\a) (digit-value #\5)
(bytevector-u8-ref #u8(1 2) 0) (bytevector-append #u8(1) #u8(2)) (utf8->string #u8(65)) (string->utf8 "A")
(exact->inexact 1/3) (inexact->exact 0.5) (exact 2.0) (inexact 1/2) (floor 2.5) (ceiling 2.5) (round 2.5) (truncate 2.5)
(quotient 7 2) (remainder 7 2) (modulo -7 2) (floor-quotient 7 2) (truncate/ 7 2) (exact-integer-sqrt 17) (expt 2 10) (sqrt 16) (exp 1) (log 100 10)
(sin 0) (cos 0) (tan 0) (asin 0) (acos 1) (atan 1 1) (number->string 3.14) (min 1 2) (max 1 2) (abs -5) (gcd 12 18) (lcm 4 6)
(zero? 0) (positive? 1) (negative? -1) (odd? 1) (even? 2) (number? 1) (integer? 1) (rational? 1/2) (real? 1.0) (complex? 1+i) (exact? 1) (inexact? 1.0) (nan? +nan.0)
(boolean? #t) (symbol? 'a) (string? "a") (char? #\a) (vector? #(1)) (pair? '(1)) (null? '()) (procedure? car) (list? '(1)) (bytevector? #u8())
(eq? 'a 'a) (eqv? 1 1) (equal? '(1) '(1)) (boolean=? #t #t) (symbol=? 'a 'a) (char=? #\a #\a) (string=? "a" "a") (string<? "a" "b")
(apply + 1 2 '(3 4)) (values 1 2) (void) (read-line) (read-char) (peek-char) (read-string 5) (read-u8) (char-ready?)
(write 'a) (write-string "s") (write-char #\a) (write-u8 1) (write-shared lst) (write-simple lst) (display "x") (newline) (flush-output-port)
(open-input-string "abc") (open-output-string) (get-output-string (open-output-string)) (open-input-bytevector #u8(1)) (open-output-bytevector)
(call-with-input-file "in.txt" read-line) (with-output-to-file "out.txt" (lambda () (display "x"))) (file-exists? "x") (delete-file "x")
(current-input-port) (current-output-port) (current-error-port) (textual-port? (current-output-port)) (close-port (current-input-port))
(command-line) (get-environment-variable "HOME") (get-environment-variables) (current-second) (current-jiffy) (jiffies-per-second) (features)
(eval '(+ 1 2) (environment '(scheme base))) (interaction-environment) (load "file.scm") (read (open-input-string "(1 2)"))
(list-copy lst) (list-set! (list 1 2) 0 9) (string-fill! (make-string 2) #\a) (vector-copy #(1 2)) (vector-append #(1) #(2)) (vector->string #(#\a)) (string->vector "a")
(exact-integer? 1) (char-foldcase #\A) (string-foldcase "A") (truncate-quotient 7 2) (boolean=? #t #t) (make-list 2 0) (assq-ref alist 'a)
(hash-table-set! (make-hash-table) 'a 1) (hash-table-ref/default (make-hash-table) 'a 0) (sort '(3 1 2) <) (list-index even? '(1 2)) (delete 1 '(1 2)) (iota 5) (string-join '("a" "b") ",")
(format #t "~a ~s ~d~%" "x" 'y 5) (assert (> 1 0)) (list-sort < '(2 1)) (reduce + 0 '(1 2 3)) (filter odd? '(1 2 3)) (remove odd? '(1 2 3)) (delete-duplicates '(1 1 2))

;;; ── Quasi-quotation ──
(define qq `(order ,(car orders) ,@(cdr orders) (nested ,(+ 1 2)) #(vec ,(+ 1 1)) . tail))
(define nested-qq `(a `(b ,(c ,(+ 1 2)))))

;;; ── Output ──
(unless (zero? (revenue orders))
  (display "revenue: ") (display (revenue orders)) (newline))
(display (string-append "ticks: " (number->string (tick)))) (newline)   ; 15
(display `(,pi ,reorder-point))
(newline)
