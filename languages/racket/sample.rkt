#lang racket
;; ── Comments ──
;; Racket showcase: warehouse inventory with structs, macros and contracts.
;; TODO: persist the catalogue. FIXME: reorder amounts ignore pack size.

#| A block comment
   #| with a nested block comment |#
   spanning lines. |#

#;(this whole datum is commented out with a datum comment)

(module+ main
  (displayln "main submodule"))

(module+ test
  (require rackunit)
  (check-equal? (+ 1 2) 3))

(module inner racket/base
  (provide helper)
  (define (helper) 'ok))

;; ── Requires and provides ──
(require racket/contract
         racket/list
         racket/match
         racket/string
         (prefix-in s: racket/set)
         (only-in racket/math pi sqr)
         (except-in racket/format ~a)
         (rename-in racket/vector [vector-map vmap])
         "helpers.rkt"
         (file "/tmp/local.rkt")
         (lib "racket/base")
         (planet example/inventory:1:0)
         (for-syntax racket/base))

(provide revenue
         (struct-out order)
         (contract-out [describe (-> order? string?)])
         (all-defined-out))

;; ── Literals ──
(define numbers
  (list 42 -7 +5 3.14 -2.5e3 1e-3 #xFF #b1010 #o755 #e1.5 #i3/4 1/2 -3/4
        +inf.0 -inf.0 +nan.0 1+2i 3.0-4.5i #d10 1e3 6.022e23))

(define chars (list #\a #\space #\newline #\tab #\nul #\x41 #λ #\U0001F4E6 #\( #\;))
(define bools (list #t #f #true #false))

(define strings
  (list "plain string"
        "escapes: \n \t \\ \" \a \b \e \f \r \v \101 \x41 λ \U0001F4E6 \
         continued"
        #<<HERE
here string, with "quotes" and \n unescaped
spanning lines
HERE
        #"byte string \x00\xff"
        #rx"^AC-[0-9]{4}$"
        #px"\\d+(?:\\.\\d+)?"
        #rx#"bytes regex"
        #px#"\\d+"))

(define symbols (list 'sym '|symbol with spaces| 'a.b 'λ '->arrow '<=? 'set! 'x->y))
(define keywords (list '#:keyword '#:another-kw))
(define quoted '(a b (c d) . e))
(define vec #(1 2 3))
(define vec2 #3(1 2))
(define hash1 #hash((a . 1) (b . 2)))
(define hash2 #hasheq((x . 1)))
(define hash3 #hashalw((k . v)))
(define box1 #&"boxed")
(define fl #fl(1.0 2.0))
(define quasi `(1 ,(+ 1 1) ,@(list 3 4)))
(define syntax-quoted #'(a b))
(define quasi-syntax #`(a #,(+ 1 2) #,@(list 3)))
(define prefab #s(point 1 2))
(define path-literal (build-path "a" 'up "b"))

;; ── Definitions ──
(define REORDER-POINT 25)
(define tax-rate 0.075)
(define-values (lo hi) (values 0 100))
(define ((curried a) b) (+ a b))

(define (add a b) (+ a b))
(define (optional a [b 2] #:scale [scale 1.0] #:flag flag . rest)
  (* scale (+ a b (length rest))))

(define square (λ (x) (* x x)))
(define cube (lambda (x) (* x x x)))
(define case-lam (case-lambda [(x) x] [(x y) (+ x y)] [args (apply + args)]))

(define/contract (revenue orders)
  (-> (listof order?) real?)
  (for/sum ([o orders] #:when (eq? (order-status o) 'paid))
    (order-total o)))

;; ── Structs ──
(struct order (number total status) #:transparent)
(struct point (x y) #:mutable #:prefab)
(struct 3d-point point (z) #:guard (λ (x y z name) (values x y z)))
(struct item (sku [qty #:auto]) #:auto-value 0 #:property prop:custom-write
  (λ (self port mode) (write-string "<item>" port)))

;; ── Control flow ──
(define (describe o)
  (match o
    [(order n _ 'paid) (format "#~a paid" n)]
    [(order n _ 'pending) (format "#~a pending" n)]
    [(order n _ (list 'cancelled reason)) (format "#~a cancelled: ~a" n reason)]
    [(? string? s) s]
    [(list a b ...) (apply + a b)]
    [(vector x y) (list x y)]
    [(cons h t) h]
    [(and x (not 0)) x]
    [(or 1 2) 'small]
    [_ "unknown"]))

(define (classify n)
  (cond
    [(< n 0) 'negative]
    [(= n 0) 'zero]
    [(and (> n 0) (< n 10)) 'small]
    [else 'large]))

(define (branches x)
  (if (zero? x) 'zero 'nonzero)
  (when (> x 0) (displayln "positive"))
  (unless (> x 0) (displayln "not positive"))
  (case x
    [(1 2 3) 'low]
    [(4 5 6) 'mid]
    [else 'high])
  (and #t x)
  (or #f x))

(define (loops lst)
  (for ([x lst]) (display x))
  (for/list ([x (in-range 10)] [y (in-naturals)] #:when (even? x)) (* x y))
  (for/vector ([x lst]) x)
  (for/hash ([k '(a b)] [v '(1 2)]) (values k v))
  (for/fold ([sum 0] [n 0]) ([x lst]) (values (+ sum x) (add1 n)))
  (for*/list ([x '(1 2)] [y '(a b)]) (cons x y))
  (for/and ([x lst]) (> x 0))
  (for/first ([x lst] #:when (> x 1)) x)
  (let loop ([i 0])
    (when (< i 3)
      (loop (add1 i)))))

;; ── Binding forms ──
(define (bindings)
  (let ([a 1] [b 2]) (+ a b))
  (let* ([a 1] [b (+ a 1)]) b)
  (letrec ([even? (λ (n) (if (zero? n) #t (odd? (sub1 n))))]
           [odd? (λ (n) (if (zero? n) #f (even? (sub1 n))))])
    (even? 10))
  (let-values ([(q r) (quotient/remainder 17 5)]) (list q r))
  (define-values (x y) (values 1 2))
  (set! x 10)
  (parameterize ([current-output-port (open-output-string)]) (display "hidden"))
  (with-handlers ([exn:fail? (λ (e) (exn-message e))]
                  [string? values])
    (raise "boom"))
  (dynamic-wind (λ () (void)) (λ () 'body) (λ () (void)))
  (call/cc (λ (k) (k 1)))
  (let/ec return (return 5)))

;; ── Macros ──
(define-syntax-rule (swap! a b)
  (let ([tmp a]) (set! a b) (set! b tmp)))

(define-syntax unless*
  (syntax-rules ()
    [(_ test body ...) (if (not test) (begin body ...) (void))]))

(define-syntax (my-if stx)
  (syntax-case stx ()
    [(_ c t e) #'(cond [c t] [else e])]))

(define-syntax (with-logging stx)
  (syntax-parse stx
    [(_ name:id body:expr ...)
     #:with msg (format "entering ~a" (syntax-e #'name))
     #'(begin (displayln msg) body ...)]))

(begin-for-syntax
  (define (helper-at-phase-1) 1))

;; ── Classes, units, generics ──
(define warehouse%
  (class object%
    (super-new)
    (init-field name)
    (field [bins 0])
    (define/public (capacity) (* bins 100))
    (define/private (secret) 1)
    (define/override (to-string) name)))

(define-generics printable (gen-print printable [port]))

(define w (new warehouse% [name "north"]))
(send w capacity)

;; ── Data ──
(define orders
  (list (order 1 120.5 'paid)
        (order 2 42 'pending)
        (order 3 0 '(cancelled "duplicate"))))

(define table (make-hash '((a . 1))))
(hash-set! table 'b 2)
(hash-ref table 'a #f)
(string-append "a" (number->string 42) (symbol->string 'sym))
(regexp-match #px"(\\d+)-(\\d+)" "10-20")
(apply + 1 2 '(3 4))
(map (curry + 1) '(1 2 3))
(sort '(3 1 2) <)
(vector-ref vec 0)
(printf "revenue: ~a\n" (revenue orders))
(fprintf (current-error-port) "~s ~v ~e\n" "s" 'v 1)

(for-each (compose displayln describe) orders)
(module+ main (main))
(define (main) (void))
